# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API CORS", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:api_token) { create(:api_token, user: user) }

  describe "regular requests" do
    it "includes CORS headers in API response" do
      get "/api/v1/me",
          headers: api_headers(token: api_token.token).merge("Origin" => "https://example.com")

      expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
    end
  end
end
