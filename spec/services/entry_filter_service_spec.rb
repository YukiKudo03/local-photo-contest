# frozen_string_literal: true

require "rails_helper"

RSpec.describe EntryFilterService do
  let(:contest) { create(:contest, :published) }

  describe "#filter with text search" do
    let!(:entry_matching) { create(:entry, contest: contest, title: "Beautiful Sunset") }
    let!(:entry_other) { create(:entry, contest: contest, title: "Mountain View") }
    let(:scope) { Entry.all }

    it "filters by text search query" do
      result = described_class.new(scope, { q: "Sunset" }).filter
      expect(result).to include(entry_matching)
    end
  end

  describe "#filter with category filter" do
    let(:category) { create(:category) }
    let(:contest_with_cat) { create(:contest, :published, category: category) }
    let!(:entry_cat) { create(:entry, contest: contest_with_cat) }
    let(:scope) { Entry.joins(:contest) }

    it "filters by category_id" do
      result = described_class.new(scope, { category_id: category.id }).filter
      expect(result).to include(entry_cat)
    end
  end

  describe "#filter with area filter" do
    let(:area) { create(:area) }
    let!(:entry_area) { create(:entry, contest: contest, area: area) }
    let(:scope) { Entry.all }

    it "filters by area_id" do
      result = described_class.new(scope, { area_id: area.id }).filter
      expect(result).to include(entry_area)
    end
  end

  describe "#filter with spot filter" do
    let(:spot) { create(:spot, contest: contest) }
    let!(:entry_spot) { create(:entry, contest: contest, spot: spot) }
    let(:scope) { Entry.all }

    it "filters by spot_id" do
      result = described_class.new(scope, { spot_id: spot.id }).filter
      expect(result).to include(entry_spot)
    end
  end

  describe "#filter with discovery_status filter" do
    let(:discovered_spot) { create(:spot, :discovered, contest: contest) }
    let(:certified_spot) { create(:spot, :certified, contest: contest) }
    let(:organizer_spot) { create(:spot, :organizer_created, contest: contest) }
    let!(:entry_discovered) { create(:entry, contest: contest, spot: discovered_spot) }
    let!(:entry_certified) { create(:entry, contest: contest, spot: certified_spot) }
    let!(:entry_organizer) { create(:entry, contest: contest, spot: organizer_spot) }
    let(:scope) { Entry.joins(:spot) }

    it "filters by discovered status" do
      result = described_class.new(scope, { discovery_status: "discovered" }).filter
      expect(result).to include(entry_discovered)
      expect(result).not_to include(entry_certified)
    end

    it "filters by certified status" do
      result = described_class.new(scope, { discovery_status: "certified" }).filter
      expect(result).to include(entry_certified)
    end

    it "filters by organizer status" do
      result = described_class.new(scope, { discovery_status: "organizer" }).filter
      expect(result).to include(entry_organizer)
    end
  end

  describe "#filter with tag filter" do
    let(:tag) { create(:tag) }
    let!(:entry_tagged) { create(:entry, contest: contest) }
    let(:scope) { Entry.all }

    before { create(:entry_tag, entry: entry_tagged, tag: tag) }

    it "filters by tag_id" do
      result = described_class.new(scope, { tag_id: tag.id }).filter
      expect(result).to include(entry_tagged)
    end
  end

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
