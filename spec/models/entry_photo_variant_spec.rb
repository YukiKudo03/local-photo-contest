# frozen_string_literal: true

require "rails_helper"

RSpec.describe Entry, "photo variants" do
  let(:entry) { create(:entry) }

  describe "PHOTO_VARIANTS" do
    it "defines four size presets" do
      expect(Entry::PHOTO_VARIANTS.keys).to eq(%i[thumb small medium large])
    end
  end

  describe "#optimized_photo" do
    context "when photo is attached" do
      it "returns a WebP variant for each size" do
        Entry::PHOTO_VARIANTS.each_key do |size|
          variant = entry.optimized_photo(size)
          expect(variant).to be_present
          expect(variant.variation.transformations[:format]).to eq(:webp)
        end
      end

      it "defaults to medium size" do
        variant = entry.optimized_photo
        expect(variant.variation.transformations).to include(resize_to_limit: [ 600, 600 ])
      end

      it "strips EXIF data from variants" do
        variant = entry.optimized_photo(:small)
        expect(variant.variation.transformations[:saver]).to eq(strip: true)
      end
    end

    context "when photo is not attached" do
      let(:entry) { build(:entry) }

      before { entry.photo.detach if entry.photo.attached? }

      it "returns nil" do
        expect(entry.optimized_photo(:medium)).to be_nil
      end
    end
  end

  describe "#photo_variant" do
    context "when photo is attached" do
      it "returns a variant without WebP format" do
        variant = entry.photo_variant(:small)
        expect(variant).to be_present
        expect(variant.variation.transformations[:format]).not_to eq(:webp)
      end

      it "strips EXIF data from variants" do
        variant = entry.photo_variant(:medium)
        expect(variant.variation.transformations[:saver]).to eq(strip: true)
      end

      it "defaults to medium size" do
        variant = entry.photo_variant
        expect(variant.variation.transformations).to include(resize_to_limit: [ 600, 600 ])
      end
    end

    context "when photo is not attached" do
      let(:entry) { build(:entry) }

      before { entry.photo.detach if entry.photo.attached? }

      it "returns nil" do
        expect(entry.photo_variant(:small)).to be_nil
      end
    end
  end
end
