# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImageAnalysisJob, type: :job do
  let(:entry) { create(:entry) }

  describe "#perform" do
    it "calls QualityScoreService" do
      quality_service = instance_double(ImageAnalysis::QualityScoreService)
      hash_service = instance_double(ImageAnalysis::ImageHashService)

      allow(ImageAnalysis::QualityScoreService).to receive(:new).with(entry).and_return(quality_service)
      allow(ImageAnalysis::ImageHashService).to receive(:new).with(entry).and_return(hash_service)
      allow(quality_service).to receive(:calculate)
      allow(hash_service).to receive(:generate_hash)

      described_class.perform_now(entry.id)

      expect(quality_service).to have_received(:calculate)
    end

    it "calls ImageHashService" do
      quality_service = instance_double(ImageAnalysis::QualityScoreService)
      hash_service = instance_double(ImageAnalysis::ImageHashService)

      allow(ImageAnalysis::QualityScoreService).to receive(:new).with(entry).and_return(quality_service)
      allow(ImageAnalysis::ImageHashService).to receive(:new).with(entry).and_return(hash_service)
      allow(quality_service).to receive(:calculate)
      allow(hash_service).to receive(:generate_hash)

      described_class.perform_now(entry.id)

      expect(hash_service).to have_received(:generate_hash)
    end

    context "when entry does not exist" do
      it "does not raise error" do
        expect { described_class.perform_now(0) }.not_to raise_error
      end
    end

    context "when entry has no photo" do
      before do
        entry.photo.purge
      end

      it "does not process" do
        expect(ImageAnalysis::QualityScoreService).not_to receive(:new)
        described_class.perform_now(entry.id)
      end
    end
  end

  describe "job configuration" do
    it "uses default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end
  end

  describe "callback integration" do
    it "enqueues ImageAnalysisJob when entry is created" do
      expect {
        create(:entry)
      }.to have_enqueued_job(ImageAnalysisJob)
    end
  end
end
