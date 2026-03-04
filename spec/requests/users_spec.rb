# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:user) { create(:user, :confirmed, name: "Test User", bio: "Photographer") }

  describe "GET /users/:id" do
    it "returns successful response" do
      get user_path(user)
      expect(response).to have_http_status(:success)
    end

    it "displays user name" do
      get user_path(user)
      expect(response.body).to include("Test User")
    end

    it "displays follower count" do
      get user_path(user)
      expect(response.body).to include(t("social.follows.followers"))
    end

    context "when signed in" do
      let(:viewer) { create(:user, :confirmed) }
      before { sign_in viewer }

      it "shows follow button" do
        get user_path(user)
        expect(response.body).to include(t("social.follows.follow"))
      end

      it "shows following state if already following" do
        create(:follow, follower: viewer, followed: user)
        get user_path(user)
        expect(response.body).to include(t("social.follows.following"))
      end
    end

    context "when viewing own profile" do
      before { sign_in user }

      it "does not show follow button for self" do
        get user_path(user)
        expect(response.body).not_to include(user_follow_path(user))
      end
    end
  end

  private

  def t(key, **options)
    I18n.t(key, **options)
  end
end
