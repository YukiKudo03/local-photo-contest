require "rails_helper"

RSpec.describe "Tutorials", type: :request do
  let(:user) { create(:user, :organizer, :confirmed) }

  before do
    sign_in user
    # シードデータの代わりにテスト用ステップを作成
    create(:tutorial_step, tutorial_type: "organizer_onboarding", step_id: "step1", position: 1)
    create(:tutorial_step, tutorial_type: "organizer_onboarding", step_id: "step2", position: 2)
    create(:tutorial_step, tutorial_type: "organizer_onboarding", step_id: "step3", position: 3)
  end

  describe "GET /tutorials/status" do
    it "returns tutorial status" do
      get status_tutorials_path, as: :json
      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)
      expect(json).to have_key("progresses")
      expect(json).to have_key("available_types")
      expect(json).to have_key("should_show_onboarding")
      expect(json).to have_key("feature_level")
      expect(json).to have_key("available_features")
    end

    it "returns available types for organizer" do
      get status_tutorials_path, as: :json
      json = JSON.parse(response.body)
      expect(json["available_types"]).to include("organizer_onboarding")
    end
  end

  describe "GET /tutorials/:tutorial_type" do
    it "returns tutorial details" do
      get tutorial_path("organizer_onboarding"), as: :json
      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)
      expect(json["steps"].length).to eq(3)
      expect(json).to have_key("settings")
    end

    it "returns error for invalid tutorial type" do
      get tutorial_path("invalid_type"), as: :json
      expect(response).to have_http_status(:bad_request).or have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /tutorials/:tutorial_type/start" do
    it "starts a tutorial" do
      post start_tutorial_path("organizer_onboarding"), as: :json
      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)
      expect(json["progress"]["current_step_id"]).to eq("step1")
    end

    it "creates a tutorial progress record" do
      expect {
        post start_tutorial_path("organizer_onboarding"), as: :json
      }.to change(TutorialProgress, :count).by(1)
    end

    it "does not duplicate progress if already started" do
      create(:tutorial_progress, user: user, tutorial_type: "organizer_onboarding", started_at: Time.current)

      expect {
        post start_tutorial_path("organizer_onboarding"), as: :json
      }.not_to change(TutorialProgress, :count)

      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /tutorials/:tutorial_type" do
    let!(:progress) { create(:tutorial_progress, :started, user: user, tutorial_type: "organizer_onboarding") }

    it "advances to next step" do
      patch tutorial_path("organizer_onboarding"),
            params: { step_id: "step1" },
            as: :json
      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)
      expect(json).to have_key("next_step")
    end

    it "advances to specific step" do
      patch tutorial_path("organizer_onboarding"),
            params: { step_id: "step1" },
            as: :json

      json = JSON.parse(response.body)
      expect(json["next_step"]).not_to be_nil
    end

    it "completes tutorial when advancing to last step" do
      progress.update!(current_step_id: "step3")

      patch tutorial_path("organizer_onboarding"),
            params: { step_id: "step3" },
            as: :json

      json = JSON.parse(response.body)
      expect(json["completed"]).to be true
    end
  end

  describe "POST /tutorials/:tutorial_type/skip" do
    let!(:progress) { create(:tutorial_progress, :started, user: user, tutorial_type: "organizer_onboarding") }

    it "skips the tutorial" do
      post skip_tutorial_path("organizer_onboarding"),
           params: { skip_all: true },
           as: :json
      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)
      expect(json).to have_key("progress")
    end
  end

  describe "POST /tutorials/:tutorial_type/reset" do
    let!(:progress) { create(:tutorial_progress, :completed, user: user, tutorial_type: "organizer_onboarding") }

    it "resets the tutorial progress" do
      post reset_tutorial_path("organizer_onboarding"), as: :json
      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)
      expect(json["success"]).to be true
    end
  end

  describe "PATCH /tutorials/settings" do
    it "updates tutorial settings" do
      patch settings_tutorials_path,
            params: { show_tutorials: false },
            as: :json
      expect(response).to have_http_status(:success)

      json = JSON.parse(response.body)
      expect(json["success"]).to be true
      expect(user.reload.tutorial_settings["show_tutorials"]).to be false
    end

    it "updates multiple settings" do
      patch settings_tutorials_path,
            params: { show_tutorials: false, show_context_help: false, reduced_motion: true },
            as: :json

      user.reload
      expect(user.tutorial_settings["show_tutorials"]).to be false
      expect(user.tutorial_settings["show_context_help"]).to be false
      expect(user.tutorial_settings["reduced_motion"]).to be true
    end
  end

  context "when not authenticated" do
    before { sign_out user }

    it "redirects to login for status" do
      get status_tutorials_path, as: :json
      expect(response).to have_http_status(:unauthorized).or have_http_status(:redirect)
    end

    it "redirects to login for show" do
      get tutorial_path("organizer_onboarding"), as: :json
      expect(response).to have_http_status(:unauthorized).or have_http_status(:redirect)
    end
  end
end
