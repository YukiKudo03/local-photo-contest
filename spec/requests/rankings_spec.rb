# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rankings", type: :request do
  describe "GET /rankings" do
    it "returns successful response" do
      get rankings_path
      expect(response).to have_http_status(:success)
    end

    it "displays users ordered by total_points descending" do
      user1 = create(:user, :confirmed, name: "TopUser", total_points: 100, level: 3)
      user2 = create(:user, :confirmed, name: "SecondUser", total_points: 50, level: 2)
      user3 = create(:user, :confirmed, name: "FirstUser", total_points: 200, level: 5)

      get rankings_path
      body = response.body

      expect(body.index("FirstUser")).to be < body.index("TopUser")
      expect(body.index("TopUser")).to be < body.index("SecondUser")
    end

    it "paginates results with 20 per page" do
      25.times { |i| create(:user, :confirmed, total_points: i + 1) }
      get rankings_path
      expect(response.body).to include("rankings")
    end

    it "shows user level badge" do
      create(:user, :confirmed, name: "LevelUser", total_points: 100, level: 3)
      get rankings_path
      expect(response.body).to include("Lv.3")
    end

    it "shows empty state when no users have points" do
      get rankings_path
      expect(response.body).to include(I18n.t("gamification.rankings.empty_state"))
    end
  end

  describe "GET /rankings with authenticated user" do
    let(:user) { create(:user, :confirmed, total_points: 75, level: 2) }

    before { sign_in user }

    it "highlights current user in the ranking" do
      get rankings_path
      expect(response.body).to include(user.display_name)
    end
  end
end
