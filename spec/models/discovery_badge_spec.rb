# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscoveryBadge, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:contest) }
  end

  describe "validations" do
    it "validates uniqueness of badge_type scoped to user and contest" do
      badge = create(:discovery_badge, :pioneer)
      duplicate = build(:discovery_badge, :pioneer, user: badge.user, contest: badge.contest)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:badge_type]).to include("は既に獲得しています")
    end

    it "allows same badge_type for different users" do
      badge = create(:discovery_badge, :pioneer)
      other_user_badge = build(:discovery_badge, :pioneer, contest: badge.contest)

      expect(other_user_badge).to be_valid
    end

    it "allows same badge_type for different contests" do
      badge = create(:discovery_badge, :pioneer)
      other_contest_badge = build(:discovery_badge, :pioneer, user: badge.user)

      expect(other_contest_badge).to be_valid
    end
  end

  describe "enums" do
    it "defines badge_type enum with correct values" do
      expect(DiscoveryBadge.badge_types).to eq({
        "pioneer" => 0,
        "explorer" => 1,
        "curator" => 2,
        "master" => 3
      })
    end
  end

  describe "#badge_name" do
    it "returns Japanese name for pioneer" do
      badge = build(:discovery_badge, :pioneer)
      expect(badge.badge_name).to eq("開拓者")
    end

    it "returns Japanese name for explorer" do
      badge = build(:discovery_badge, :explorer)
      expect(badge.badge_name).to eq("探検家")
    end

    it "returns Japanese name for curator" do
      badge = build(:discovery_badge, :curator)
      expect(badge.badge_name).to eq("キュレーター")
    end

    it "returns Japanese name for master" do
      badge = build(:discovery_badge, :master)
      expect(badge.badge_name).to eq("マスター")
    end
  end

  describe "#badge_description" do
    it "returns i18n description for pioneer" do
      badge = build(:discovery_badge, :pioneer)
      expect(badge.badge_description).to be_present
    end
  end

  describe "factory" do
    it "creates a valid badge" do
      badge = build(:discovery_badge)
      expect(badge).to be_valid
    end

    it "creates different badge types" do
      pioneer = create(:discovery_badge, :pioneer)
      explorer = create(:discovery_badge, :explorer, user: pioneer.user, contest: create(:contest))

      expect(pioneer.badge_pioneer?).to be true
      expect(explorer.badge_explorer?).to be true
    end
  end
end
