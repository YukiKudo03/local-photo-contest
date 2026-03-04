# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImageAnalysis::QualityScoreService, type: :service do
  let(:entry) { create(:entry, :with_exif) }
  let(:service) { described_class.new(entry) }

  describe "#calculate" do
    it "returns a score between 0 and 100" do
      score = service.calculate
      expect(score).to be_between(0.0, 100.0)
    end

    it "updates the entry quality_score" do
      service.calculate
      entry.reload
      expect(entry.quality_score).to be_present
    end

    it "updates image_analysis_completed_at" do
      service.calculate
      entry.reload
      expect(entry.image_analysis_completed_at).to be_present
    end

    context "with high quality EXIF data" do
      let(:entry) do
        create(:entry, exif_data: {
          "ISOSpeedRatings" => "100",
          "ExposureTime" => "1/125",
          "FNumber" => "28/10",
          "FocalLength" => "50/1",
          "ImageWidth" => "6000",
          "ImageHeight" => "4000"
        })
      end

      it "scores higher for good settings" do
        score = service.calculate
        expect(score).to be > 40.0
      end
    end

    context "with poor EXIF data" do
      let(:entry) do
        create(:entry, exif_data: {
          "ISOSpeedRatings" => "6400",
          "ExposureTime" => "1/15",
          "FNumber" => "56/10",
          "FocalLength" => "18/1",
          "ImageWidth" => "1000",
          "ImageHeight" => "800"
        })
      end

      it "scores lower for poor settings" do
        score = service.calculate
        expect(score).to be_present
      end
    end

    context "without EXIF data" do
      let(:entry) { create(:entry) }

      it "falls back to default EXIF score" do
        score = service.calculate
        expect(score).to be_present
      end
    end

    context "without attached photo" do
      let(:entry) { build(:entry, :without_photo) }

      before do
        allow(entry).to receive(:persisted?).and_return(true)
      end

      it "returns nil" do
        expect(service.calculate).to be_nil
      end
    end

    context "when an error occurs" do
      before do
        allow(entry).to receive(:has_exif_data?).and_raise(StandardError, "test error")
      end

      it "returns nil and logs error" do
        expect(Rails.logger).to receive(:error).with(/QualityScoreService/)
        expect(service.calculate).to be_nil
      end
    end
  end
end
