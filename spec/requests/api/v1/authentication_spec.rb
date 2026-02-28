# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Authentication", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:api_token) { create(:api_token, user: user) }

  describe "token authentication" do
    it "returns 401 without authorization header" do
      get "/api/v1/me", headers: api_headers
      expect(response).to have_http_status(:unauthorized)
      expect(json_response["error"]["code"]).to eq("unauthorized")
    end

    it "returns 401 with invalid token" do
      get "/api/v1/me", headers: api_headers(token: "invalid")
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with revoked token" do
      api_token.revoke!
      get "/api/v1/me", headers: api_headers(token: api_token.token)
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with expired token" do
      expired = create(:api_token, :expired, user: user)
      get "/api/v1/me", headers: api_headers(token: expired.token)
      expect(response).to have_http_status(:unauthorized)
    end

    it "succeeds with valid token" do
      get "/api/v1/me", headers: api_headers(token: api_token.token)
      expect(response).to have_http_status(:ok)
    end

    it "updates last_used_at on successful auth" do
      expect(api_token.last_used_at).to be_nil
      get "/api/v1/me", headers: api_headers(token: api_token.token)
      expect(api_token.reload.last_used_at).to be_present
    end
  end

  describe "error format" do
    it "returns JSON error for 404" do
      get "/api/v1/contests/999999", headers: api_headers(token: api_token.token)
      expect(response).to have_http_status(:not_found)
      expect(json_response).to have_key("error")
      expect(json_response["error"]).to have_key("code")
      expect(json_response["error"]).to have_key("message")
    end
  end
end
