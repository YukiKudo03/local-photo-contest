# frozen_string_literal: true

require "rails_helper"

RSpec.describe EntryFilterService do
  let(:contest) { create(:contest, :published) }

  describe "EXIF filters" do
    let!(:canon_entry) { create(:entry, :with_exif, contest: contest) }
    let!(:nikon_entry) { create(:entry, :with_exif_nikon, contest: contest) }
    let!(:no_exif_entry) { create(:entry, contest: contest) }
    let(:scope) { Entry.all }

    describe "camera_make filter" do
      it "returns only entries matching camera make" do
        result = described_class.new(scope, { camera_make: "Canon" }).filter
        expect(result).to include(canon_entry)
        expect(result).not_to include(nikon_entry, no_exif_entry)
      end

      it "returns only Nikon entries" do
        result = described_class.new(scope, { camera_make: "Nikon" }).filter
        expect(result).to include(nikon_entry)
        expect(result).not_to include(canon_entry)
      end
    end

    describe "camera_model filter" do
      it "returns only entries matching camera model" do
        result = described_class.new(scope, { camera_model: "Canon EOS R5" }).filter
        expect(result).to include(canon_entry)
        expect(result).not_to include(nikon_entry, no_exif_entry)
      end
    end

    describe "focal_length range filter" do
      it "filters by minimum focal length" do
        result = described_class.new(scope, { focal_length_min: "60" }).filter
        expect(result).to include(nikon_entry) # 85mm
        expect(result).not_to include(canon_entry) # 50mm
      end

      it "filters by maximum focal length" do
        result = described_class.new(scope, { focal_length_max: "60" }).filter
        expect(result).to include(canon_entry) # 50mm
        expect(result).not_to include(nikon_entry) # 85mm
      end
    end

    describe "iso range filter" do
      it "filters by minimum ISO" do
        result = described_class.new(scope, { iso_min: "300" }).filter
        expect(result).to include(canon_entry) # ISO 400
        expect(result).not_to include(nikon_entry) # ISO 200
      end

      it "filters by maximum ISO" do
        result = described_class.new(scope, { iso_max: "300" }).filter
        expect(result).to include(nikon_entry) # ISO 200
        expect(result).not_to include(canon_entry) # ISO 400
      end
    end
  end
end
