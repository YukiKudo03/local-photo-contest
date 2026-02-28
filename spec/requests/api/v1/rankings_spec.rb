# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Rankings", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:api_token) { create(:api_token, user: user) }

  describe "GET /api/v1/contests/:contest_id/rankings" do
    let(:contest) { create(:contest, :accepting_entries) }

    before do
      # Create entries while contest is accepting
      @entry1 = create(:entry, contest: contest)
      @entry2 = create(:entry, contest: contest)
      # Transition to finished with results announced
      contest.update_columns(status: 2, results_announced_at: Time.current)
      create(:contest_ranking, :first_place, contest: contest, entry: @entry1)
      create(:contest_ranking, :second_place, contest: contest, entry: @entry2)
    end

    it "returns rankings for announced contest" do
      get "/api/v1/contests/#{contest.id}/rankings",
          headers: api_headers(token: api_token.token)

      expect(response).to have_http_status(:ok)
      rankings = json_response["data"]
      expect(rankings.size).to eq(2)
      expect(rankings.first["rank"]).to eq(1)
      expect(rankings.first).to have_key("entry")
      expect(rankings.first["entry"]).to have_key("title")
    end

    it "returns 403 when results not announced" do
      unannounced = create(:contest, :accepting_entries)
      entry = create(:entry, contest: unannounced)
      unannounced.update_columns(status: 2)
      create(:contest_ranking, :first_place, contest: unannounced, entry: entry)

      get "/api/v1/contests/#{unannounced.id}/rankings",
          headers: api_headers(token: api_token.token)

      expect(response).to have_http_status(:forbidden)
      expect(json_response["error"]["code"]).to eq("forbidden")
    end

    it "returns 404 for draft contest" do
      draft = create(:contest, :draft)
      get "/api/v1/contests/#{draft.id}/rankings",
          headers: api_headers(token: api_token.token)

      expect(response).to have_http_status(:not_found)
    end
  end
end
