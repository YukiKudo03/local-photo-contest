# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Entries", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:api_token) { create(:api_token, user: user) }
  let(:contest) { create(:contest, :published) }

  describe "GET /api/v1/contests/:contest_id/entries" do
    let!(:visible_entry) { create(:entry, contest: contest) }
    let!(:hidden_entry) { create(:entry, contest: contest, moderation_status: :moderation_hidden) }

    it "returns visible entries only" do
      get "/api/v1/contests/#{contest.id}/entries",
          headers: api_headers(token: api_token.token)

      expect(response).to have_http_status(:ok)
      ids = json_response["data"].map { |e| e["id"] }
      expect(ids).to include(visible_entry.id)
      expect(ids).not_to include(hidden_entry.id)
    end

    it "includes photo_url in entries" do
      get "/api/v1/contests/#{contest.id}/entries",
          headers: api_headers(token: api_token.token)

      entry_data = json_response["data"].first
      expect(entry_data).to have_key("photo_url")
    end

    it "paginates results" do
      get "/api/v1/contests/#{contest.id}/entries",
          params: { page: 1, per_page: 1 },
          headers: api_headers(token: api_token.token)

      expect(json_response["data"].size).to eq(1)
      expect(json_response["meta"]).to have_key("total_count")
    end
  end

  describe "GET /api/v1/entries/:id" do
    let(:entry) { create(:entry, contest: contest) }
    let!(:vote) { create(:vote, entry: entry, user: user) }

    it "returns entry detail with photo variants" do
      get "/api/v1/entries/#{entry.id}",
          headers: api_headers(token: api_token.token)

      expect(response).to have_http_status(:ok)
      data = json_response["data"]
      expect(data["id"]).to eq(entry.id)
      expect(data).to have_key("photo_variants")
      expect(data["photo_variants"]).to have_key("thumb")
      expect(data["photo_variants"]).to have_key("medium")
    end

    it "includes votes_count" do
      get "/api/v1/entries/#{entry.id}",
          headers: api_headers(token: api_token.token)

      expect(json_response["data"]["votes_count"]).to eq(1)
    end

    it "includes current_user_voted" do
      get "/api/v1/entries/#{entry.id}",
          headers: api_headers(token: api_token.token)

      expect(json_response["data"]["current_user_voted"]).to be true
    end

    it "includes spot info when present" do
      spot = create(:spot, :with_coordinates, contest: contest)
      entry_with_spot = create(:entry, contest: contest, spot: spot)

      get "/api/v1/entries/#{entry_with_spot.id}",
          headers: api_headers(token: api_token.token)

      expect(json_response["data"]["spot"]).to be_present
      expect(json_response["data"]["spot"]["name"]).to eq(spot.name)
    end

    it "returns 404 for nonexistent entry" do
      get "/api/v1/entries/999999",
          headers: api_headers(token: api_token.token)

      expect(response).to have_http_status(:not_found)
    end
  end
end
