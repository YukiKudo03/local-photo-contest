# frozen_string_literal: true

require "rails_helper"

RSpec.describe ModerationJob, type: :job do
  include ActiveJob::TestHelper

  let(:contest) { create(:contest, :published, moderation_enabled: true) }
  let(:entry) { create(:entry, contest: contest) }

  let(:mock_provider) { instance_double(Moderation::Providers::BaseProvider, name: "mock") }
  let(:clean_result) do
    Moderation::Providers::BaseProvider::Result.new(
      labels: [],
      max_confidence: nil,
      raw_response: {}
    )
  end

  before do
    allow(Moderation::Providers).to receive(:current).and_return(mock_provider)
    allow(mock_provider).to receive(:analyze).and_return(clean_result)
  end

  describe "#perform" do
    it "calls ModerationService.moderate" do
      expect(Moderation::ModerationService).to receive(:moderate).with(entry).and_call_original

      described_class.new.perform(entry.id)
    end

    it "processes entry successfully" do
      described_class.new.perform(entry.id)

      expect(entry.reload).to be_moderation_approved
    end

    context "when entry does not exist" do
      it "logs warning and returns early" do
        expect(Rails.logger).to receive(:warn).with(/Entry 99999 not found/)

        described_class.new.perform(99999)
      end

      it "does not raise error" do
        expect { described_class.new.perform(99999) }.not_to raise_error
      end
    end

    context "when ModerationService returns error" do
      let(:error_result) do
        Moderation::ModerationService::Result.new(
          entry: entry,
          status: :error,
          error: "Provider error"
        )
      end

      before do
        allow(Moderation::ModerationService).to receive(:moderate).and_return(error_result)
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/moderation failed/)

        described_class.new.perform(entry.id)
      end
    end

    context "when unexpected error occurs" do
      before do
        allow(Moderation::ModerationService).to receive(:moderate)
          .and_raise(StandardError, "Unexpected error")
      end

      it "re-raises the error for retry" do
        expect { described_class.new.perform(entry.id) }.to raise_error(StandardError)
      end

      it "sets entry to requires_review" do
        expect { described_class.new.perform(entry.id) }.to raise_error(StandardError)

        expect(entry.reload).to be_moderation_requires_review
      end
    end
  end

  describe "job configuration" do
    it "uses the moderation queue" do
      expect(described_class.queue_name).to eq("moderation")
    end
  end

  describe "enqueueing" do
    it "enqueues the job with correct arguments" do
      clear_enqueued_jobs

      expect {
        described_class.perform_later(entry.id)
      }.to have_enqueued_job(described_class).with(entry.id).on_queue("moderation")
    end
  end

  describe "entry callback integration" do
    it "enqueues job when entry is created with moderation enabled" do
      expect {
        create(:entry, contest: contest)
      }.to have_enqueued_job(ModerationJob)
    end

    it "does not enqueue job when moderation is disabled" do
      contest.update!(moderation_enabled: false)

      expect {
        create(:entry, contest: contest)
      }.not_to have_enqueued_job(ModerationJob)
    end
  end

  describe "end-to-end flow" do
    it "moderates entry when job is performed" do
      entry = nil

      perform_enqueued_jobs do
        entry = create(:entry, contest: contest)
      end

      expect(entry.reload).to be_moderation_approved
      expect(entry.moderation_result).to be_present
    end

    it "creates moderation result with provider name" do
      entry = nil

      perform_enqueued_jobs do
        entry = create(:entry, contest: contest)
      end

      expect(entry.moderation_result.provider).to eq("mock")
    end
  end
end
