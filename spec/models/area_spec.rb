# frozen_string_literal: true

require "rails_helper"

RSpec.describe Area, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:contests).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:entries).dependent(:nullify) }
  end

  describe "validations" do
    subject { build(:area) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(50) }
    it { is_expected.to validate_length_of(:prefecture).is_at_most(20) }
    it { is_expected.to validate_length_of(:city).is_at_most(50) }
    it { is_expected.to validate_length_of(:address).is_at_most(200) }
    it { is_expected.to validate_length_of(:description).is_at_most(2000) }

    describe "uniqueness" do
      let(:user) { create(:user, :organizer, :confirmed) }
      let!(:existing_area) { create(:area, user: user, name: "テストエリア") }

      it "allows same name for different users" do
        other_user = create(:user, :organizer, :confirmed)
        new_area = build(:area, user: other_user, name: "テストエリア")
        expect(new_area).to be_valid
      end

      it "rejects same name for same user" do
        new_area = build(:area, user: user, name: "テストエリア")
        expect(new_area).not_to be_valid
        expect(new_area.errors[:name]).to include("同じ名前のエリアが既に存在します")
      end
    end

    describe "boundary_geojson validation" do
      it "is valid with valid GeoJSON" do
        area = build(:area, :with_boundary)
        expect(area).to be_valid
      end

      it "is invalid with invalid JSON" do
        area = build(:area, boundary_geojson: "invalid json")
        expect(area).not_to be_valid
        expect(area.errors[:boundary_geojson]).to include("は有効なJSON形式である必要があります")
      end

      it "is valid without boundary_geojson" do
        area = build(:area, boundary_geojson: nil)
        expect(area).to be_valid
      end
    end
  end

  describe "scopes" do
    describe ".ordered" do
      let(:user) { create(:user, :organizer, :confirmed) }
      let!(:area2) { create(:area, user: user, position: 2) }
      let!(:area1) { create(:area, user: user, position: 1) }
      let!(:area3) { create(:area, user: user, position: 3) }

      it "returns areas ordered by position" do
        expect(Area.ordered).to eq([ area1, area2, area3 ])
      end
    end

    describe ".for_user" do
      let(:user) { create(:user, :organizer, :confirmed) }
      let(:other_user) { create(:user, :organizer, :confirmed) }
      let!(:user_area) { create(:area, user: user) }
      let!(:other_area) { create(:area, user: other_user) }

      it "returns only areas for the specified user" do
        expect(Area.for_user(user)).to include(user_area)
        expect(Area.for_user(user)).not_to include(other_area)
      end
    end
  end

  describe "callbacks" do
    describe "#set_position" do
      let(:user) { create(:user, :organizer, :confirmed) }

      it "sets position automatically if not provided" do
        area = create(:area, user: user, position: nil)
        expect(area.position).to be_present
      end

      it "increments position based on existing areas for same user" do
        create(:area, user: user, position: 5)
        area = create(:area, user: user, position: nil)
        expect(area.position).to eq(6)
      end

      it "does not consider other users' areas for position" do
        other_user = create(:user, :organizer, :confirmed)
        create(:area, user: other_user, position: 10)
        area = create(:area, user: user, position: nil)
        expect(area.position).to eq(1)
      end
    end
  end

  describe "#full_address" do
    it "returns concatenated address parts" do
      area = build(:area, prefecture: "東京都", city: "渋谷区", address: "道玄坂1-1-1")
      expect(area.full_address).to eq("東京都渋谷区道玄坂1-1-1")
    end

    it "handles blank parts" do
      area = build(:area, prefecture: "東京都", city: nil, address: "道玄坂1-1-1")
      expect(area.full_address).to eq("東京都道玄坂1-1-1")
    end

    it "returns empty string when all parts are blank" do
      area = build(:area, prefecture: nil, city: nil, address: nil)
      expect(area.full_address).to eq("")
    end
  end

  describe "#has_boundary?" do
    it "returns true when boundary_geojson is present" do
      area = build(:area, :with_boundary)
      expect(area.has_boundary?).to be true
    end

    it "returns false when boundary_geojson is blank" do
      area = build(:area, boundary_geojson: nil)
      expect(area.has_boundary?).to be false
    end
  end

  describe "#boundary_polygon" do
    it "returns parsed GeoJSON when valid" do
      area = build(:area, :with_boundary)
      expect(area.boundary_polygon).to be_a(Hash)
      expect(area.boundary_polygon["type"]).to eq("Polygon")
    end

    it "returns nil when boundary_geojson is blank" do
      area = build(:area, boundary_geojson: nil)
      expect(area.boundary_polygon).to be_nil
    end

    it "returns nil when boundary_geojson is invalid JSON" do
      area = build(:area)
      area.boundary_geojson = "invalid"
      expect(area.boundary_polygon).to be_nil
    end
  end

  describe "#center_coordinates" do
    it "returns [lat, lng] when coordinates are present" do
      area = build(:area, :with_coordinates)
      expect(area.center_coordinates).to eq([ 35.6580339, 139.7016358 ])
    end

    it "returns nil when latitude is blank" do
      area = build(:area, latitude: nil, longitude: 139.7016358)
      expect(area.center_coordinates).to be_nil
    end

    it "returns nil when longitude is blank" do
      area = build(:area, latitude: 35.6580339, longitude: nil)
      expect(area.center_coordinates).to be_nil
    end
  end

  describe "#owned_by?" do
    let(:user) { create(:user, :organizer, :confirmed) }
    let(:other_user) { create(:user, :organizer, :confirmed) }
    let(:area) { create(:area, user: user) }

    it "returns true for the owner" do
      expect(area.owned_by?(user)).to be true
    end

    it "returns false for other users" do
      expect(area.owned_by?(other_user)).to be false
    end

    it "returns false for nil" do
      expect(area.owned_by?(nil)).to be false
    end
  end
end
