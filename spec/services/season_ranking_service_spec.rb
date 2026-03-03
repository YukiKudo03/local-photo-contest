# frozen_string_literal: true

require "rails_helper"

RSpec.describe SeasonRankingService do
  let(:user1) { create(:user, :confirmed, name: "User One") }
  let(:user2) { create(:user, :confirmed, name: "User Two") }
  let(:user3) { create(:user, :confirmed, name: "User Three") }

  describe "#monthly_rankings" do
    let(:this_month_start) { Time.current.beginning_of_month }

    before do
      # User1: 50 points this month
      create(:user_point, user: user1, points: 30, action_type: "submit_entry", earned_at: this_month_start + 1.day)
      create(:user_point, user: user1, points: 20, action_type: "comment", earned_at: this_month_start + 2.days)

      # User2: 80 points this month
      create(:user_point, user: user2, points: 50, action_type: "prize_1st", earned_at: this_month_start + 1.day)
      create(:user_point, user: user2, points: 30, action_type: "submit_entry", earned_at: this_month_start + 2.days)

      # User3: 10 points this month, 100 from last month
      create(:user_point, user: user3, points: 10, action_type: "vote", earned_at: this_month_start + 1.day)
      create(:user_point, user: user3, points: 100, action_type: "prize_1st", earned_at: 2.months.ago)
    end

    it "returns users ranked by points in the current month" do
      service = described_class.new
      rankings = service.monthly_rankings

      expect(rankings[0][:user]).to eq(user2)
      expect(rankings[0][:points]).to eq(80)
      expect(rankings[1][:user]).to eq(user1)
      expect(rankings[1][:points]).to eq(50)
      expect(rankings[2][:user]).to eq(user3)
      expect(rankings[2][:points]).to eq(10)
    end

    it "returns rankings for a specific month" do
      service = described_class.new
      rankings = service.monthly_rankings(date: 2.months.ago)

      expect(rankings[0][:user]).to eq(user3)
      expect(rankings[0][:points]).to eq(100)
    end
  end

  describe "#quarterly_rankings" do
    before do
      create(:user_point, user: user1, points: 50, action_type: "submit_entry",
             earned_at: Time.current.beginning_of_quarter + 1.day)
      create(:user_point, user: user2, points: 100, action_type: "prize_1st",
             earned_at: Time.current.beginning_of_quarter + 5.days)
    end

    it "returns users ranked by points in the current quarter" do
      service = described_class.new
      rankings = service.quarterly_rankings

      expect(rankings[0][:user]).to eq(user2)
      expect(rankings[0][:points]).to eq(100)
      expect(rankings[1][:user]).to eq(user1)
      expect(rankings[1][:points]).to eq(50)
    end
  end

  describe "#season_summary" do
    it "returns aggregated stats for the period" do
      create(:user_point, user: user1, points: 10, action_type: "vote", earned_at: Time.current.beginning_of_month + 1.day)
      create(:user_point, user: user1, points: 10, action_type: "submit_entry", earned_at: Time.current.beginning_of_month + 2.days)

      service = described_class.new
      summary = service.season_summary(:monthly)

      expect(summary[:total_participants]).to eq(1)
      expect(summary[:total_points_awarded]).to eq(20)
      expect(summary[:period_label]).to be_present
    end
  end
end
