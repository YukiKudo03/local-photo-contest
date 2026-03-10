# frozen_string_literal: true

require "rails_helper"

RSpec.describe ExifAccessible, type: :model do
  describe "#exif_focal_length" do
    it "returns nil for invalid rational value" do
      entry = build(:entry, exif_data: { "FocalLength" => "0/0" })
      expect(entry.exif_focal_length).to be_nil
    end
  end

  describe "#exif_aperture" do
    it "returns nil for invalid rational value" do
      entry = build(:entry, exif_data: { "FNumber" => "0/0" })
      expect(entry.exif_aperture).to be_nil
    end
  end
end
