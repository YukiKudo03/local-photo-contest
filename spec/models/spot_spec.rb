# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spot, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:contest) }
    it { is_expected.to belong_to(:discovered_by).class_name("User").optional }
    it { is_expected.to belong_to(:certified_by).class_name("User").optional }
    it { is_expected.to have_many(:entries).dependent(:nullify) }
    it { is_expected.to have_many(:spot_votes).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:spot) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_length_of(:address).is_at_most(200) }
    it { is_expected.to validate_length_of(:description).is_at_most(1000) }
    it { is_expected.to validate_presence_of(:category) }

    describe "uniqueness" do
      let(:contest) { create(:contest) }
      let!(:existing_spot) { create(:spot, contest: contest, name: "テストスポット") }

      it "allows same name for different contests" do
        other_contest = create(:contest)
        new_spot = build(:spot, contest: other_contest, name: "テストスポット")
        expect(new_spot).to be_valid
      end

      it "rejects same name for same contest" do
        new_spot = build(:spot, contest: contest, name: "テストスポット")
        expect(new_spot).not_to be_valid
        expect(new_spot.errors[:name]).to include("は既にこのコンテストに登録されています")
      end
    end
  end

  describe "enums" do
    it {
      is_expected.to define_enum_for(:category).with_values(
        restaurant: 0,
        retail: 1,
        service: 2,
        landmark: 3,
        public_facility: 4,
        park: 5,
        temple_shrine: 6,
        other: 99
      )
    }

    it {
      is_expected.to define_enum_for(:discovery_status)
        .with_values(
          organizer_created: 0,
          discovered: 1,
          certified: 2,
          rejected: 3
        )
        .with_prefix(:discovery)
    }
  end

  describe "scopes" do
    describe ".ordered" do
      let(:contest) { create(:contest) }
      let!(:spot2) { create(:spot, contest: contest, position: 2) }
      let!(:spot1) { create(:spot, contest: contest, position: 1) }
      let!(:spot3) { create(:spot, contest: contest, position: 3) }

      it "returns spots ordered by position" do
        expect(Spot.ordered).to eq([ spot1, spot2, spot3 ])
      end
    end

    describe ".pending_certification" do
      let(:contest) { create(:contest) }
      let!(:discovered_spot) { create(:spot, :discovered, contest: contest) }
      let!(:certified_spot) { create(:spot, :certified, contest: contest) }
      let!(:organizer_spot) { create(:spot, :organizer_created, contest: contest) }

      it "returns only spots with discovered status" do
        expect(Spot.pending_certification).to include(discovered_spot)
        expect(Spot.pending_certification).not_to include(certified_spot)
        expect(Spot.pending_certification).not_to include(organizer_spot)
      end
    end

    describe ".certified_or_organizer" do
      let(:contest) { create(:contest) }
      let!(:discovered_spot) { create(:spot, :discovered, contest: contest) }
      let!(:certified_spot) { create(:spot, :certified, contest: contest) }
      let!(:organizer_spot) { create(:spot, :organizer_created, contest: contest) }
      let!(:rejected_spot) { create(:spot, :rejected, contest: contest) }

      it "returns spots with organizer_created or certified status" do
        result = Spot.certified_or_organizer
        expect(result).to include(certified_spot)
        expect(result).to include(organizer_spot)
        expect(result).not_to include(discovered_spot)
        expect(result).not_to include(rejected_spot)
      end
    end

    describe ".discovered_by_user" do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }
      let(:contest) { create(:contest) }
      let!(:user_spot) { create(:spot, :discovered, contest: contest, discovered_by: user) }
      let!(:other_spot) { create(:spot, :discovered, contest: contest, discovered_by: other_user) }

      it "returns spots discovered by the specified user" do
        expect(Spot.discovered_by_user(user)).to include(user_spot)
        expect(Spot.discovered_by_user(user)).not_to include(other_spot)
      end
    end
  end

  describe "callbacks" do
    describe "#set_position" do
      let(:contest) { create(:contest) }

      it "sets position automatically if not provided" do
        spot = create(:spot, contest: contest, position: nil)
        expect(spot.position).to be_present
      end

      it "increments position based on existing spots" do
        create(:spot, contest: contest, position: 5)
        spot = create(:spot, contest: contest, position: nil)
        expect(spot.position).to eq(6)
      end
    end
  end

  describe "#coordinates" do
    it "returns [lat, lng] when coordinates are present" do
      spot = build(:spot, :with_coordinates)
      expect(spot.coordinates).to eq([ 35.6580339, 139.7016358 ])
    end

    it "returns nil when latitude is blank" do
      spot = build(:spot, latitude: nil, longitude: 139.7016358)
      expect(spot.coordinates).to be_nil
    end

    it "returns nil when longitude is blank" do
      spot = build(:spot, latitude: 35.6580339, longitude: nil)
      expect(spot.coordinates).to be_nil
    end
  end

  describe "#category_name" do
    it "returns Japanese name for restaurant" do
      spot = build(:spot, :restaurant)
      expect(spot.category_name).to eq("飲食店")
    end

    it "returns Japanese name for retail" do
      spot = build(:spot, :retail)
      expect(spot.category_name).to eq("小売店")
    end

    it "returns Japanese name for landmark" do
      spot = build(:spot, :landmark)
      expect(spot.category_name).to eq("名所・ランドマーク")
    end

    it "returns Japanese name for park" do
      spot = build(:spot, :park)
      expect(spot.category_name).to eq("公園・広場")
    end

    it "returns Japanese name for temple_shrine" do
      spot = build(:spot, :temple_shrine)
      expect(spot.category_name).to eq("寺社仏閣")
    end
  end

  describe "#discovery_status_name" do
    it "returns Japanese name for organizer_created" do
      spot = build(:spot, :organizer_created)
      expect(spot.discovery_status_name).to eq("主催者作成")
    end

    it "returns Japanese name for discovered" do
      spot = build(:spot, :discovered)
      expect(spot.discovery_status_name).to eq("発掘中")
    end

    it "returns Japanese name for certified" do
      spot = build(:spot, :certified)
      expect(spot.discovery_status_name).to eq("認定済み")
    end

    it "returns Japanese name for rejected" do
      spot = build(:spot, :rejected)
      expect(spot.discovery_status_name).to eq("却下")
    end
  end

  describe "#discovered?" do
    it "returns true when discovered_by is present" do
      user = create(:user)
      spot = build(:spot, discovered_by: user)
      expect(spot.discovered?).to be true
    end

    it "returns false when discovered_by is nil" do
      spot = build(:spot, discovered_by: nil)
      expect(spot.discovered?).to be false
    end
  end

  describe "#certify!" do
    let(:spot) { create(:spot, :discovered) }
    let(:certifier) { create(:user) }

    it "updates status to certified" do
      spot.certify!(certifier)
      expect(spot.reload.discovery_certified?).to be true
    end

    it "sets certified_by to the certifier" do
      spot.certify!(certifier)
      expect(spot.reload.certified_by).to eq(certifier)
    end

    it "sets certified_at to current time" do
      spot.certify!(certifier)
      expect(spot.reload.certified_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "#reject!" do
    let(:spot) { create(:spot, :discovered) }
    let(:rejector) { create(:user) }
    let(:reason) { "不適切なスポットです" }

    it "updates status to rejected" do
      spot.reject!(rejector, reason)
      expect(spot.reload.discovery_rejected?).to be true
    end

    it "sets certified_by to the rejector" do
      spot.reject!(rejector, reason)
      expect(spot.reload.certified_by).to eq(rejector)
    end

    it "sets rejection_reason" do
      spot.reject!(rejector, reason)
      expect(spot.reload.rejection_reason).to eq(reason)
    end
  end

  describe "#voted_by?" do
    let(:user) { create(:user) }
    let(:spot) { create(:spot, :certified) }

    it "returns true when user has voted" do
      create(:spot_vote, user: user, spot: spot)
      expect(spot.voted_by?(user)).to be true
    end

    it "returns false when user has not voted" do
      expect(spot.voted_by?(user)).to be false
    end
  end

  describe "#voteable?" do
    it "returns true for organizer_created spots" do
      spot = build(:spot, :organizer_created)
      expect(spot.voteable?).to be true
    end

    it "returns true for certified spots" do
      spot = build(:spot, :certified)
      expect(spot.voteable?).to be true
    end

    it "returns false for discovered spots" do
      spot = build(:spot, :discovered)
      expect(spot.voteable?).to be false
    end

    it "returns false for rejected spots" do
      spot = build(:spot, :rejected)
      expect(spot.voteable?).to be false
    end
  end
end
