# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SeasonRankings", type: :request do
  describe "GET /rankings/monthly" do
    it "returns successful response" do
      get monthly_rankings_path
      expect(response).to have_http_status(:success)
    end

    it "displays monthly ranking header" do
      get monthly_rankings_path
      expect(response.body).to include(I18n.t("gamification.season_rankings.monthly_title"))
    end

    it "shows users with points in current month" do
      user = create(:user, :confirmed, name: "Monthly Hero")
      create(:user_point, user: user, points: 50, action_type: "submit_entry", earned_at: Time.current.beginning_of_month + 1.day)

      get monthly_rankings_path
      expect(response.body).to include("Monthly Hero")
      expect(response.body).to include("50")
    end

    it "accepts month/year params" do
      get monthly_rankings_path, params: { year: 2026, month: 1 }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /rankings/quarterly" do
    it "returns successful response" do
      get quarterly_rankings_path
      expect(response).to have_http_status(:success)
    end

    it "displays quarterly ranking header" do
      get quarterly_rankings_path
      expect(response.body).to include(I18n.t("gamification.season_rankings.quarterly_title"))
    end

    it "accepts year/quarter params" do
      get quarterly_rankings_path, params: { year: 2026, quarter: 1 }
      expect(response).to have_http_status(:success)
    end
  end

  describe "empty state" do
    it "shows empty state message when no points in period" do
      get monthly_rankings_path
      expect(response.body).to include(I18n.t("gamification.season_rankings.empty_state"))
    end
  end
end
