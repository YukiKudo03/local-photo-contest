require "rails_helper"

RSpec.describe "Feedback", type: :request do
  let!(:terms) { create(:terms_of_service, :current) }
  let!(:user) { create(:user, :confirmed) }

  before do
    create(:terms_acceptance, user: user, terms_of_service: terms)
  end

  describe "POST /feedback/action" do
    context "when authenticated" do
      before { sign_in user }

      it "returns JSON with milestones and feature_level" do
        post "/feedback/action", params: { action_type: "first_login", metadata: {} }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json).to have_key("milestones")
        expect(json).to have_key("feature_level")
        expect(json["milestones"]).to be_an(Array)
        expect(json["feature_level"]).to be_present
      end

      it "returns at most 3 recent milestones" do
        post "/feedback/action", params: { action_type: "first_login" }

        json = JSON.parse(response.body)
        expect(json["milestones"].length).to be <= 3
      end

      it "returns milestones with badge_info when milestones exist" do
        UserMilestone.create!(user: user, milestone_type: "first_vote", achieved_at: Time.current)

        post "/feedback/action", params: { action_type: "first_submission" }

        json = JSON.parse(response.body)
        expect(json["milestones"]).to be_an(Array)
        expect(json["milestones"].length).to be >= 1
        expect(json["milestones"].first).to have_key("name")
      end

      it "accepts action_type without metadata" do
        post "/feedback/action", params: { action_type: "first_login" }

        expect(response).to have_http_status(:success)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post "/feedback/action", params: { action_type: "first_login" }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user has locale set" do
      before do
        user.update_column(:locale, "en")
        sign_in user
      end

      it "uses user locale" do
        post "/feedback/action", params: { action_type: "first_login" }

        expect(response).to have_http_status(:success)
      end
    end
  end
end
