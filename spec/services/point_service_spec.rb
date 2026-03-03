# frozen_string_literal: true

require "rails_helper"

RSpec.describe PointService do
  let(:user) { create(:user, :confirmed) }
  let(:service) { described_class.new(user) }

  describe "#award_for_action" do
    it "creates a user_point record for submit_entry" do
      contest = create(:contest, :published)
      entry = create(:entry, user: user, contest: contest)

      expect {
        service.award_for_action("submit_entry", source: entry)
      }.to change(UserPoint, :count).by(1)

      point = UserPoint.last
      expect(point.points).to eq(10)
      expect(point.action_type).to eq("submit_entry")
      expect(point.source).to eq(entry)
    end

    it "creates a user_point record for vote" do
      expect {
        service.award_for_action("vote")
      }.to change(UserPoint, :count).by(1)

      expect(UserPoint.last.points).to eq(1)
    end

    it "creates a user_point record for comment" do
      expect {
        service.award_for_action("comment")
      }.to change(UserPoint, :count).by(1)

      expect(UserPoint.last.points).to eq(3)
    end

    it "updates user total_points" do
      service.award_for_action("submit_entry")
      expect(user.reload.total_points).to eq(10)
    end

    it "accumulates total_points across multiple actions" do
      service.award_for_action("submit_entry")  # 10
      service.award_for_action("vote")           # 1
      service.award_for_action("comment")        # 3
      expect(user.reload.total_points).to eq(14)
    end

    it "does not duplicate points for same source" do
      contest = create(:contest, :published)
      entry = create(:entry, user: user, contest: contest)

      service.award_for_action("submit_entry", source: entry)
      service.award_for_action("submit_entry", source: entry)
      expect(UserPoint.where(user: user, action_type: "submit_entry").count).to eq(1)
    end
  end

  describe "#award_for_prize" do
    let(:organizer) { create(:user, :organizer, :confirmed) }
    let(:contest) { create(:contest, :finished, user: organizer) }
    let(:entry) do
      e = build(:entry, user: user, contest: contest)
      e.save(validate: false)
      e
    end

    it "awards 50 points for 1st place" do
      ranking = create(:contest_ranking, :first_place, contest: contest, entry: entry)
      service.award_for_prize(ranking)
      expect(UserPoint.last.points).to eq(50)
    end

    it "awards 30 points for 2nd place" do
      ranking = create(:contest_ranking, :second_place, contest: contest, entry: entry)
      service.award_for_prize(ranking)
      expect(UserPoint.last.points).to eq(30)
    end

    it "awards 20 points for 3rd place" do
      ranking = create(:contest_ranking, :third_place, contest: contest, entry: entry)
      service.award_for_prize(ranking)
      expect(UserPoint.last.points).to eq(20)
    end
  end

  describe "#recalculate_total!" do
    it "recalculates total from all point records" do
      create(:user_point, user: user, points: 10, action_type: "submit_entry")
      create(:user_point, user: user, points: 3, action_type: "comment")
      user.update_column(:total_points, 0)

      service.recalculate_total!
      expect(user.reload.total_points).to eq(13)
    end
  end
end
