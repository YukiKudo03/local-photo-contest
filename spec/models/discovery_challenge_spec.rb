# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscoveryChallenge, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:contest) }
    it { is_expected.to have_many(:challenge_entries).dependent(:destroy) }
    it { is_expected.to have_many(:entries).through(:challenge_entries) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_length_of(:theme).is_at_most(100) }

    context "when ends_at is before starts_at" do
      it "is invalid" do
        challenge = build(:discovery_challenge, starts_at: 1.day.from_now, ends_at: 1.day.ago)
        expect(challenge).not_to be_valid
        expect(challenge.errors[:ends_at]).to include("は開始日時より後に設定してください")
      end
    end

    context "when ends_at is after starts_at" do
      it "is valid" do
        challenge = build(:discovery_challenge, starts_at: 1.day.from_now, ends_at: 2.days.from_now)
        expect(challenge).to be_valid
      end
    end
  end

  describe "enums" do
    it "defines status enum with correct values" do
      expect(DiscoveryChallenge.statuses).to eq({
        "draft" => 0,
        "active" => 1,
        "finished" => 2
      })
    end
  end

  describe "scopes" do
    let!(:contest) { create(:contest) }

    describe ".active_now" do
      let!(:active_now) { create(:discovery_challenge, :active_now, contest: contest) }
      let!(:draft) { create(:discovery_challenge, :draft, contest: contest) }
      let!(:finished) { create(:discovery_challenge, :finished, contest: contest) }

      it "returns only challenges that are active and within period" do
        expect(DiscoveryChallenge.active_now).to include(active_now)
        expect(DiscoveryChallenge.active_now).not_to include(draft)
        expect(DiscoveryChallenge.active_now).not_to include(finished)
      end
    end
  end

  describe "#status_name" do
    it "returns Japanese name for draft" do
      challenge = build(:discovery_challenge, :draft)
      expect(challenge.status_name).to eq("下書き")
    end

    it "returns Japanese name for active" do
      challenge = build(:discovery_challenge, :active)
      expect(challenge.status_name).to eq("開催中")
    end

    it "returns Japanese name for finished" do
      challenge = build(:discovery_challenge, :finished)
      expect(challenge.status_name).to eq("終了")
    end
  end

  describe "#entries_count" do
    let(:contest) { create(:contest, :published) }
    let(:challenge) { create(:discovery_challenge, contest: contest) }

    it "returns the count of entries" do
      entry1 = create(:entry, contest: contest)
      entry2 = create(:entry, contest: contest)
      create(:challenge_entry, discovery_challenge: challenge, entry: entry1)
      create(:challenge_entry, discovery_challenge: challenge, entry: entry2)

      expect(challenge.entries_count).to eq(2)
    end
  end

  describe "#discovered_spots_count" do
    let(:contest) { create(:contest, :published) }
    let(:challenge) { create(:discovery_challenge, contest: contest) }

    it "returns the count of discovered or certified spots" do
      discovered_spot = create(:spot, :discovered, contest: contest)
      certified_spot = create(:spot, :certified, contest: contest)
      rejected_spot = create(:spot, :rejected, contest: contest)

      entry_with_discovered = create(:entry, contest: contest, spot: discovered_spot)
      entry_with_certified = create(:entry, contest: contest, spot: certified_spot)
      entry_with_rejected = create(:entry, contest: contest, spot: rejected_spot)

      create(:challenge_entry, discovery_challenge: challenge, entry: entry_with_discovered)
      create(:challenge_entry, discovery_challenge: challenge, entry: entry_with_certified)
      create(:challenge_entry, discovery_challenge: challenge, entry: entry_with_rejected)

      expect(challenge.discovered_spots_count).to eq(2)
    end
  end
end
