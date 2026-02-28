# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Spots", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:api_token) { create(:api_token, user: user) }
  let(:contest) { create(:contest, :published) }

  describe "GET /api/v1/contests/:contest_id/spots" do
    let!(:organizer_spot) { create(:spot, :organizer_created, :with_coordinates, contest: contest) }
    let!(:certified_spot) { create(:spot, :certified, :with_coordinates, contest: contest) }
    let!(:rejected_spot) { create(:spot, :rejected, contest: contest) }
    let!(:discovered_spot) { create(:spot, :discovered, contest: contest) }

    it "returns certified and organizer-created spots" do
      get "/api/v1/contests/#{contest.id}/spots",
          headers: api_headers(token: api_token.token)

      expect(response).to have_http_status(:ok)
      ids = json_response["data"].map { |s| s["id"] }
      expect(ids).to include(organizer_spot.id, certified_spot.id)
      expect(ids).not_to include(rejected_spot.id, discovered_spot.id)
    end

    it "includes coordinates" do
      get "/api/v1/contests/#{contest.id}/spots",
          headers: api_headers(token: api_token.token)

      spot = json_response["data"].find { |s| s["id"] == organizer_spot.id }
      expect(spot["latitude"]).to be_present
      expect(spot["longitude"]).to be_present
    end

    it "includes entries_count" do
      create(:entry, contest: contest, spot: organizer_spot)

      get "/api/v1/contests/#{contest.id}/spots",
          headers: api_headers(token: api_token.token)

      spot = json_response["data"].find { |s| s["id"] == organizer_spot.id }
      expect(spot["entries_count"]).to eq(1)
    end
  end
end
