# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ModerationService, type: :service do
  let(:contest) { create(:contest, :published, moderation_enabled: true, moderation_threshold: 60.0) }
  let(:entry) { create(:entry, contest: contest) }

  let(:mock_provider) { instance_double(Moderation::Providers::BaseProvider, name: "mock") }
  let(:clean_result) do
    Moderation::Providers::BaseProvider::Result.new(
      labels: [],
      max_confidence: nil,
      raw_response: { "ModerationLabels" => [] }
    )
  end
  let(:violation_result) do
    Moderation::Providers::BaseProvider::Result.new(
      labels: [ { "Name" => "Explicit Nudity", "Confidence" => 85.0 } ],
      max_confidence: 85.0,
      raw_response: { "ModerationLabels" => [ { "Name" => "Explicit Nudity", "Confidence" => 85.0 } ] }
    )
  end
  let(:borderline_result) do
    Moderation::Providers::BaseProvider::Result.new(
      labels: [ { "Name" => "Suggestive", "Confidence" => 55.0 } ],
      max_confidence: 55.0,
      raw_response: { "ModerationLabels" => [ { "Name" => "Suggestive", "Confidence" => 55.0 } ] }
    )
  end

  before do
    allow(Moderation::Providers).to receive(:current).and_return(mock_provider)
  end

  describe ".moderate" do
    context "when moderation is disabled for contest" do
      before { contest.update!(moderation_enabled: false) }

      it "returns skipped result" do
        result = described_class.moderate(entry)

        expect(result).to be_skipped
        expect(result).to be_success
      end

      it "does not call the provider" do
        expect(mock_provider).not_to receive(:analyze)
        described_class.moderate(entry)
      end
    end

    context "when global moderation is disabled" do
      before { allow(Moderation::Providers).to receive(:enabled?).and_return(false) }

      it "returns skipped result" do
        result = described_class.moderate(entry)

        expect(result).to be_skipped
      end
    end

    context "when entry has no photo" do
      let(:entry) { build(:entry, :without_photo, contest: contest) }

      before { entry.save(validate: false) }

      it "returns skipped result" do
        result = described_class.moderate(entry)

        expect(result).to be_skipped
      end
    end

    context "when entry already has moderation result" do
      before { create(:moderation_result, entry: entry) }

      it "returns skipped result" do
        result = described_class.moderate(entry)

        expect(result).to be_skipped
      end
    end

    context "when photo passes moderation" do
      before { allow(mock_provider).to receive(:analyze).and_return(clean_result) }

      it "creates approved moderation result" do
        result = described_class.moderate(entry)

        expect(result).to be_success
        expect(result.moderation_result).to be_moderation_approved
      end

      it "sets entry status to approved" do
        described_class.moderate(entry)

        expect(entry.reload).to be_moderation_approved
      end

      it "stores empty labels" do
        described_class.moderate(entry)

        expect(entry.moderation_result.labels).to eq([])
      end
    end

    context "when violation exceeds threshold" do
      before { allow(mock_provider).to receive(:analyze).and_return(violation_result) }

      it "creates rejected moderation result" do
        result = described_class.moderate(entry)

        expect(result).to be_success
        expect(result.moderation_result).to be_moderation_rejected
      end

      it "sets entry status to hidden" do
        described_class.moderate(entry)

        expect(entry.reload).to be_moderation_hidden
      end

      it "stores detected labels" do
        described_class.moderate(entry)

        expect(entry.moderation_result.labels).to include(hash_including("Name" => "Explicit Nudity"))
      end

      it "stores max confidence" do
        described_class.moderate(entry)

        expect(entry.moderation_result.max_confidence).to eq(85.0)
      end
    end

    context "when violation is below threshold" do
      before { allow(mock_provider).to receive(:analyze).and_return(borderline_result) }

      it "creates requires_review moderation result" do
        result = described_class.moderate(entry)

        expect(result).to be_success
        expect(result.moderation_result).to be_moderation_requires_review
      end

      it "sets entry status to requires_review" do
        described_class.moderate(entry)

        expect(entry.reload).to be_moderation_requires_review
      end
    end

    context "when provider is not configured" do
      before do
        allow(Moderation::Providers).to receive(:current)
          .and_raise(Moderation::Providers::ProviderNotConfiguredError, "No provider")
      end

      it "returns error result" do
        result = described_class.moderate(entry)

        expect(result).not_to be_success
        expect(result.error).to include("No provider")
      end

      it "sets entry status to requires_review" do
        described_class.moderate(entry)

        expect(entry.reload).to be_moderation_requires_review
      end
    end

    context "when provider raises analysis error" do
      before do
        allow(mock_provider).to receive(:analyze)
          .and_raise(Moderation::Providers::RekognitionProvider::AnalysisError, "API error")
      end

      it "returns error result" do
        result = described_class.moderate(entry)

        expect(result).not_to be_success
        expect(result.error).to include("API error")
      end

      it "sets entry status to requires_review" do
        described_class.moderate(entry)

        expect(entry.reload).to be_moderation_requires_review
      end
    end

    context "when unexpected error occurs" do
      before do
        allow(mock_provider).to receive(:analyze).and_raise(StandardError, "Unexpected")
      end

      it "returns error result" do
        result = described_class.moderate(entry)

        expect(result).not_to be_success
        expect(result.error).to include("Unexpected")
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).at_least(:once)
        described_class.moderate(entry)
      end
    end
  end

  describe "Result" do
    describe "#success?" do
      it "returns true when no error" do
        result = Moderation::ModerationService::Result.new(
          entry: entry,
          status: :approved,
          error: nil
        )
        expect(result).to be_success
      end

      it "returns false when error present" do
        result = Moderation::ModerationService::Result.new(
          entry: entry,
          status: :error,
          error: "Something went wrong"
        )
        expect(result).not_to be_success
      end
    end

    describe "#skipped?" do
      it "returns true when status is skipped" do
        result = Moderation::ModerationService::Result.new(
          entry: entry,
          status: :skipped
        )
        expect(result).to be_skipped
      end

      it "returns false when status is not skipped" do
        result = Moderation::ModerationService::Result.new(
          entry: entry,
          status: :approved
        )
        expect(result).not_to be_skipped
      end
    end
  end
end
