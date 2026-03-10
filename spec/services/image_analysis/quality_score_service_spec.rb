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

    context "with ISO 101-200 range" do
      let(:entry) do
        create(:entry, exif_data: {
          "ISOSpeedRatings" => "150",
          "ExposureTime" => "1/125",
          "FNumber" => "28/10",
          "FocalLength" => "50/1",
          "ImageWidth" => "6000",
          "ImageHeight" => "4000"
        })
      end

      it "scores ISO in 101-200 range" do
        score = service.calculate
        expect(score).to be_present
      end
    end

    context "with ISO 401-800 range" do
      let(:entry) do
        create(:entry, exif_data: {
          "ISOSpeedRatings" => "600",
          "ExposureTime" => "1/125",
          "FNumber" => "28/10",
          "FocalLength" => "50/1",
          "ImageWidth" => "6000",
          "ImageHeight" => "4000"
        })
      end

      it "scores ISO in 401-800 range" do
        score = service.calculate
        expect(score).to be_present
      end
    end

    context "with ISO 801-1600 range" do
      let(:entry) do
        create(:entry, exif_data: {
          "ISOSpeedRatings" => "1200",
          "ExposureTime" => "1/125",
          "FNumber" => "28/10",
          "FocalLength" => "50/1",
          "ImageWidth" => "6000",
          "ImageHeight" => "4000"
        })
      end

      it "scores ISO in 801-1600 range" do
        score = service.calculate
        expect(score).to be_present
      end
    end

    context "with slow exposure time (0.125-1.0)" do
      let(:entry) do
        create(:entry, exif_data: {
          "ISOSpeedRatings" => "100",
          "ExposureTime" => "1/4",
          "FNumber" => "28/10",
          "FocalLength" => "50/1",
          "ImageWidth" => "6000",
          "ImageHeight" => "4000"
        })
      end

      it "scores slow exposure range" do
        score = service.calculate
        expect(score).to be_present
      end
    end

    context "with very slow exposure time (>1.0)" do
      let(:entry) do
        create(:entry, exif_data: {
          "ISOSpeedRatings" => "100",
          "ExposureTime" => "2/1",
          "FNumber" => "28/10",
          "FocalLength" => "50/1",
          "ImageWidth" => "6000",
          "ImageHeight" => "4000"
        })
      end

      it "scores very slow exposure" do
        score = service.calculate
        expect(score).to be_present
      end
    end

    context "with invalid exposure time string" do
      let(:entry) do
        create(:entry, exif_data: {
          "ISOSpeedRatings" => "100",
          "ExposureTime" => "invalid",
          "FNumber" => "28/10",
          "FocalLength" => "50/1",
          "ImageWidth" => "6000",
          "ImageHeight" => "4000"
        })
      end

      it "falls back to default exposure score" do
        score = service.calculate
        expect(score).to be_present
      end
    end

    context "with 12-20 megapixel resolution" do
      let(:entry) do
        create(:entry, exif_data: {
          "ISOSpeedRatings" => "100",
          "ExposureTime" => "1/125",
          "FNumber" => "28/10",
          "FocalLength" => "50/1",
          "ImageWidth" => "4000",
          "ImageHeight" => "3500"
        })
      end

      it "scores 12-20 megapixel range" do
        score = service.calculate
        expect(score).to be_present
      end
    end

    context "with 8-12 megapixel resolution" do
      let(:entry) do
        create(:entry, exif_data: {
          "ISOSpeedRatings" => "100",
          "ExposureTime" => "1/125",
          "FNumber" => "28/10",
          "FocalLength" => "50/1",
          "ImageWidth" => "3500",
          "ImageHeight" => "2800"
        })
      end

      it "scores 8-12 megapixel range" do
        score = service.calculate
        expect(score).to be_present
      end
    end

    context "with 4-8 megapixel resolution" do
      let(:entry) do
        create(:entry, exif_data: {
          "ISOSpeedRatings" => "100",
          "ExposureTime" => "1/125",
          "FNumber" => "28/10",
          "FocalLength" => "50/1",
          "ImageWidth" => "2500",
          "ImageHeight" => "2000"
        })
      end

      it "scores 4-8 megapixel range" do
        score = service.calculate
        expect(score).to be_present
      end
    end

    context "with invalid FNumber" do
      let(:entry) do
        create(:entry, exif_data: {
          "ISOSpeedRatings" => "100",
          "ExposureTime" => "1/125",
          "FNumber" => "invalid",
          "FocalLength" => "50/1",
          "ImageWidth" => "6000",
          "ImageHeight" => "4000"
        })
      end

      it "falls back to default lens score" do
        score = service.calculate
        expect(score).to be_present
      end
    end
  end

  describe "private MiniMagick scoring methods" do
    let(:entry) { create(:entry) }

    context "sharpness_score success path" do
      it "computes score from Laplacian standard deviation" do
        allow(MiniMagick).to receive(:convert).and_return("0.05\n")
        score = service.send(:sharpness_score, double("image", path: "/tmp/test.jpg"))
        expect(score).to eq(10.0)
      end
    end

    context "sharpness_score rescue path" do
      it "returns 10.0 on error" do
        allow(MiniMagick).to receive(:convert).and_raise(StandardError, "convert error")
        score = service.send(:sharpness_score, double("image", path: "/tmp/test.jpg"))
        expect(score).to eq(10.0)
      end
    end

    context "dynamic_range_score success path" do
      it "computes score from range value" do
        allow(MiniMagick).to receive(:identify).and_return("0.8\n")
        score = service.send(:dynamic_range_score, double("image", path: "/tmp/test.jpg"))
        expect(score).to eq(12.0)
      end
    end

    context "dynamic_range_score rescue path" do
      it "returns 7.5 on error" do
        allow(MiniMagick).to receive(:identify).and_raise(StandardError, "identify error")
        score = service.send(:dynamic_range_score, double("image", path: "/tmp/test.jpg"))
        expect(score).to eq(7.5)
      end
    end

    context "brightness_score with mean in 0.2-0.3 range" do
      it "returns 10.0" do
        allow(MiniMagick).to receive(:identify).and_return("0.25\n")
        score = service.send(:brightness_score, double("image", path: "/tmp/test.jpg"))
        expect(score).to eq(10.0)
      end
    end

    context "brightness_score with mean in 0.1-0.2 range" do
      it "returns 5.0" do
        allow(MiniMagick).to receive(:identify).and_return("0.15\n")
        score = service.send(:brightness_score, double("image", path: "/tmp/test.jpg"))
        expect(score).to eq(5.0)
      end
    end

    context "brightness_score with extreme mean (<0.1)" do
      it "returns 2.0" do
        allow(MiniMagick).to receive(:identify).and_return("0.05\n")
        score = service.send(:brightness_score, double("image", path: "/tmp/test.jpg"))
        expect(score).to eq(2.0)
      end
    end

    context "brightness_score rescue path" do
      it "returns 7.5 on error" do
        allow(MiniMagick).to receive(:identify).and_raise(StandardError, "identify error")
        score = service.send(:brightness_score, double("image", path: "/tmp/test.jpg"))
        expect(score).to eq(7.5)
      end
    end
  end
end
