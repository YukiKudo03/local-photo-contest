# frozen_string_literal: true

require "rails_helper"

RSpec.describe "My API Tokens", type: :request do
  let(:user) { create(:user, :confirmed) }

  before { sign_in user }

  describe "GET /my/api_tokens" do
    it "displays token list" do
      token = create(:api_token, user: user, name: "テストトークン")

      get my_api_tokens_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("テストトークン")
    end

    it "does not show other users tokens" do
      other = create(:user, :confirmed)
      create(:api_token, user: other, name: "他人のトークン")

      get my_api_tokens_path

      expect(response.body).not_to include("他人のトークン")
    end
  end

  describe "POST /my/api_tokens" do
    it "creates a new token" do
      expect {
        post my_api_tokens_path, params: { api_token: { name: "新規トークン" } }
      }.to change(ApiToken, :count).by(1)

      expect(response).to redirect_to(my_api_tokens_path)
      follow_redirect!
      expect(response.body).to include("新規トークン")
    end

    it "shows the raw token value after creation" do
      post my_api_tokens_path, params: { api_token: { name: "新規トークン" } }

      follow_redirect!
      # Raw token should be displayed in flash or page
      expect(response.body).to include(ApiToken.last.token)
    end

    it "renders index on invalid token creation" do
      allow_any_instance_of(ApiToken).to receive(:save).and_return(false)

      post my_api_tokens_path, params: { api_token: { name: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /my/api_tokens/:id" do
    it "revokes the token" do
      token = create(:api_token, user: user)

      delete my_api_token_path(token)

      expect(token.reload.revoked_at).to be_present
    end

    it "cannot revoke other users token" do
      other = create(:user, :confirmed)
      token = create(:api_token, user: other)

      delete my_api_token_path(token)

      expect(response).to redirect_to(my_api_tokens_path)
      expect(token.reload.revoked_at).to be_nil
    end
  end
end
