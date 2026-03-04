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
  end
end
