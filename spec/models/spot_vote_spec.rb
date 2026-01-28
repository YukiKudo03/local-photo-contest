# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpotVote, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:spot).counter_cache(:votes_count) }
  end

  describe "validations" do
    subject { create(:spot_vote) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:spot_id).with_message("は既にこのスポットに投票しています") }

    context "when spot is not certified or organizer_created" do
      let(:discovered_spot) { create(:spot, :discovered) }

      it "is invalid" do
        vote = build(:spot_vote, spot: discovered_spot)
        expect(vote).not_to be_valid
        expect(vote.errors[:spot]).to include("は認定済みスポットのみ投票可能です")
      end
    end

    context "when spot is certified" do
      let(:certified_spot) { create(:spot, :certified) }

      it "is valid" do
        vote = build(:spot_vote, spot: certified_spot)
        expect(vote).to be_valid
      end
    end

    context "when spot is organizer_created" do
      let(:organizer_spot) { create(:spot, :organizer_created) }

      it "is valid" do
        vote = build(:spot_vote, spot: organizer_spot)
        expect(vote).to be_valid
      end
    end
  end

  describe "counter_cache" do
    let(:spot) { create(:spot, :certified) }

    it "increments votes_count when vote is created" do
      expect {
        create(:spot_vote, spot: spot)
      }.to change { spot.reload.votes_count }.by(1)
    end

    it "decrements votes_count when vote is destroyed" do
      vote = create(:spot_vote, spot: spot)

      expect {
        vote.destroy
      }.to change { spot.reload.votes_count }.by(-1)
    end
  end
end
