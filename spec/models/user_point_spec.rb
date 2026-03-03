# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserPoint, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    let(:user) { create(:user, :confirmed) }

    it "is valid with valid attributes" do
      point = UserPoint.new(user: user, points: 10, action_type: "submit_entry", earned_at: Time.current)
      expect(point).to be_valid
    end

    it "requires user" do
      point = UserPoint.new(points: 10, action_type: "submit_entry", earned_at: Time.current)
      expect(point).not_to be_valid
    end

    it "requires points" do
      point = UserPoint.new(user: user, action_type: "submit_entry", earned_at: Time.current)
      expect(point).not_to be_valid
    end

    it "requires action_type" do
      point = UserPoint.new(user: user, points: 10, earned_at: Time.current)
      expect(point).not_to be_valid
    end

    it "validates action_type inclusion" do
      point = UserPoint.new(user: user, points: 10, action_type: "invalid", earned_at: Time.current)
      expect(point).not_to be_valid
    end

    it "validates points is positive" do
      point = UserPoint.new(user: user, points: -5, action_type: "vote", earned_at: Time.current)
      expect(point).not_to be_valid
    end

    it "requires earned_at" do
      point = UserPoint.new(user: user, points: 10, action_type: "vote")
      expect(point).not_to be_valid
    end
  end

  describe "POINT_VALUES" do
    it "defines point values for each action type" do
      expect(UserPoint::POINT_VALUES).to include(
        "submit_entry" => 10,
        "vote" => 1,
        "comment" => 3,
        "prize_1st" => 50,
        "prize_2nd" => 30,
        "prize_3rd" => 20,
        "prize_other" => 10,
        "milestone_achieved" => 5
      )
    end
  end

  describe "scopes" do
    let(:user) { create(:user, :confirmed) }

    describe ".for_period" do
      it "returns points within date range" do
        old_point = UserPoint.create!(user: user, points: 10, action_type: "vote", earned_at: 2.months.ago)
        recent_point = UserPoint.create!(user: user, points: 10, action_type: "vote", earned_at: 1.day.ago)

        results = UserPoint.for_period(1.month.ago, Time.current)
        expect(results).to include(recent_point)
        expect(results).not_to include(old_point)
      end
    end

    describe ".by_action_type" do
      it "filters by action type" do
        vote_point = UserPoint.create!(user: user, points: 1, action_type: "vote", earned_at: Time.current)
        entry_point = UserPoint.create!(user: user, points: 10, action_type: "submit_entry", earned_at: Time.current)

        expect(UserPoint.by_action_type("vote")).to include(vote_point)
        expect(UserPoint.by_action_type("vote")).not_to include(entry_point)
      end
    end
  end
end
