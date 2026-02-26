# frozen_string_literal: true

require "rails_helper"
require "mini_magick"

RSpec.describe ExifExtractionJob, type: :job do
  let(:entry) { create(:entry, taken_at: nil, latitude: nil, longitude: nil) }

  describe "#perform" do
    it "stores exif_data on the entry" do
      mock_exif = {
        "Make" => "Canon",
        "Model" => "EOS R5",
        "DateTimeOriginal" => "2025:06:15 10:30:00"
      }

      allow_any_instance_of(MiniMagick::Image).to receive(:exif).and_return(mock_exif)

      described_class.perform_now(entry.id)
      entry.reload

      expect(entry.exif_data).to include("Make" => "Canon", "Model" => "EOS R5")
    end

    it "auto-fills taken_at from EXIF DateTimeOriginal" do
      mock_exif = { "DateTimeOriginal" => "2025:06:15 10:30:00" }
      allow_any_instance_of(MiniMagick::Image).to receive(:exif).and_return(mock_exif)

      described_class.perform_now(entry.id)
      entry.reload

      expect(entry.taken_at).to eq(Date.new(2025, 6, 15))
    end

    it "auto-fills latitude and longitude from EXIF GPS data" do
      mock_exif = {
        "GPSLatitude" => "35/1, 41/1, 2244/100",
        "GPSLatitudeRef" => "N",
        "GPSLongitude" => "139/1, 41/1, 3024/100",
        "GPSLongitudeRef" => "E"
      }
      allow_any_instance_of(MiniMagick::Image).to receive(:exif).and_return(mock_exif)

      described_class.perform_now(entry.id)
      entry.reload

      expect(entry.latitude).to be_within(0.001).of(35.6896)
      expect(entry.longitude).to be_within(0.001).of(139.6917)
      expect(entry.location_exif?).to be true
    end

    it "does not overwrite existing taken_at" do
      original_date = Date.new(2024, 1, 1)
      entry.update_column(:taken_at, original_date)

      mock_exif = { "DateTimeOriginal" => "2025:06:15 10:30:00" }
      allow_any_instance_of(MiniMagick::Image).to receive(:exif).and_return(mock_exif)

      described_class.perform_now(entry.id)
      entry.reload

      expect(entry.taken_at).to eq(original_date)
    end

    it "handles missing entry gracefully" do
      expect { described_class.perform_now(-1) }.not_to raise_error
    end

    it "handles empty EXIF data" do
      allow_any_instance_of(MiniMagick::Image).to receive(:exif).and_return({})

      expect { described_class.perform_now(entry.id) }.not_to raise_error
      entry.reload
      expect(entry.exif_data).to be_nil
    end

    it "handles MiniMagick errors gracefully" do
      allow_any_instance_of(MiniMagick::Image).to receive(:exif).and_raise(MiniMagick::Error)

      expect { described_class.perform_now(entry.id) }.not_to raise_error
    end
  end
end
