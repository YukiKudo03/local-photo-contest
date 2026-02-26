# frozen_string_literal: true

require "rails_helper"

RSpec.describe "EmailPreferences", type: :request do
  let(:user) { create(:user, :confirmed) }

  describe "GET /email_preferences/:token" do
    context "with valid token" do
      it "renders the preferences form" do
        get email_preference_path(token: user.unsubscribe_token)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("メール通知設定")
      end
    end

    context "with invalid token" do
      it "redirects to root" do
        get email_preference_path(token: "invalid_token")
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /email_preferences/:token" do
    context "with valid token" do
      it "updates email preferences" do
        patch email_preference_path(token: user.unsubscribe_token),
              params: { user: { email_on_comment: false, email_on_vote: true } }

        expect(response).to redirect_to(email_preference_path(token: user.unsubscribe_token))
        user.reload
        expect(user.email_on_comment).to be false
        expect(user.email_on_vote).to be true
      end
    end

    context "with invalid token" do
      it "redirects to root" do
        patch email_preference_path(token: "invalid_token"),
              params: { user: { email_on_comment: false } }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
