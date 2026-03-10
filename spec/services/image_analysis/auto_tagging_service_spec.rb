# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImageAnalysis::AutoTaggingService, type: :service do
  let(:entry) { create(:entry) }
  let(:service) { described_class.new(entry) }

  describe "#perform" do
    context "when AWS Rekognition is available", if: defined?(Aws::Rekognition) do
      let(:provider) { instance_double(Moderation::Providers::RekognitionProvider) }
      let(:labels) do
        [
          { "Name" => "Landscape", "Confidence" => 95.5, "Categories" => [], "Parents" => [ "Nature" ] },
          { "Name" => "Mountain", "Confidence" => 88.3, "Categories" => [], "Parents" => [ "Nature", "Outdoors" ] },
          { "Name" => "Sky", "Confidence" => 82.1, "Categories" => [], "Parents" => [] }
        ]
      end
      let(:label_result) do
        Moderation::Providers::RekognitionProvider::LabelResult.new(
          labels: labels,
          raw_response: { "Labels" => labels }
        )
      end

      before do
        allow(Moderation::Providers::RekognitionProvider).to receive(:new).and_return(provider)
        allow(provider).to receive(:detect_labels).and_return(label_result)
      end

      it "creates tags from Rekognition labels" do
        expect { service.perform }.to change(Tag, :count).by(3)
      end

      it "creates entry_tags linking entry to tags" do
        expect { service.perform }.to change(EntryTag, :count).by(3)
      end

      it "stores confidence scores" do
        service.perform
        entry_tag = EntryTag.find_by(entry: entry, tag: Tag.find_by(name: "landscape"))
        expect(entry_tag.confidence).to eq(95.5)
      end

      it "infers category from parents" do
        service.perform
        tag = Tag.find_by(name: "landscape")
        expect(tag.category).to eq("scene")
      end

      it "does not create duplicate tags" do
        create(:tag, name: "landscape")
        expect { service.perform }.to change(Tag, :count).by(2)
      end

      it "does not create duplicate entry_tags" do
        service.perform
        expect { service.perform }.not_to change(EntryTag, :count)
      end
    end

    context "when AWS is not configured" do
      before do
        hide_const("Aws::Rekognition") if defined?(Aws::Rekognition)
      end

      it "skips tagging without error" do
        expect { service.perform }.not_to change(Tag, :count)
      end
    end

    context "when entry has no photo" do
      let(:entry) { build(:entry, :without_photo) }

      before do
        allow(entry).to receive(:persisted?).and_return(true)
      end

      it "skips tagging" do
        expect { service.perform }.not_to change(Tag, :count)
      end
    end

    context "when ConfigurationError is raised", if: defined?(Aws::Rekognition) do
      let(:provider) { instance_double(Moderation::Providers::RekognitionProvider) }

      before do
        allow(Moderation::Providers::RekognitionProvider).to receive(:new).and_return(provider)
        allow(provider).to receive(:detect_labels).and_raise(
          Moderation::Providers::RekognitionProvider::ConfigurationError, "AWS not configured"
        )
      end

      it "logs info and does not raise" do
        allow(Rails.logger).to receive(:info).and_call_original
        expect { service.perform }.not_to raise_error
        expect(Rails.logger).to have_received(:info).with(/AWS not configured/).at_least(:once)
      end
    end

    context "when AnalysisError is raised", if: defined?(Aws::Rekognition) do
      let(:provider) { instance_double(Moderation::Providers::RekognitionProvider) }

      before do
        allow(Moderation::Providers::RekognitionProvider).to receive(:new).and_return(provider)
        allow(provider).to receive(:detect_labels).and_raise(
          Moderation::Providers::RekognitionProvider::AnalysisError, "analysis failed"
        )
      end

      it "logs error and does not raise" do
        expect(Rails.logger).to receive(:error).with(/Analysis failed/)
        expect { service.perform }.not_to raise_error
      end
    end

    context "when unexpected StandardError is raised", if: defined?(Aws::Rekognition) do
      let(:provider) { instance_double(Moderation::Providers::RekognitionProvider) }

      before do
        allow(Moderation::Providers::RekognitionProvider).to receive(:new).and_return(provider)
        allow(provider).to receive(:detect_labels).and_raise(StandardError, "unexpected")
      end

      it "logs error and does not raise" do
        expect(Rails.logger).to receive(:error).with(/Unexpected error/)
        expect { service.perform }.not_to raise_error
      end
    end

    context "category inference from Rekognition categories", if: defined?(Aws::Rekognition) do
      let(:provider) { instance_double(Moderation::Providers::RekognitionProvider) }
      let(:labels) do
        [
          { "Name" => "Surfing", "Confidence" => 90.0, "Categories" => ["Sport"], "Parents" => [] }
        ]
      end
      let(:label_result) do
        Moderation::Providers::RekognitionProvider::LabelResult.new(
          labels: labels,
          raw_response: { "Labels" => labels }
        )
      end

      before do
        allow(Moderation::Providers::RekognitionProvider).to receive(:new).and_return(provider)
        allow(provider).to receive(:detect_labels).and_return(label_result)
      end

      it "infers category from Categories field" do
        service.perform
        tag = Tag.find_by(name: "surfing")
        expect(tag.category).to eq("activity")
      end
    end
  end
end
