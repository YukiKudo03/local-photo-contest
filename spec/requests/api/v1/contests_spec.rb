# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Contests", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:api_token) { create(:api_token, user: user) }

  describe "GET /api/v1/contests" do
    let!(:published) { create(:contest, :published) }
    let!(:finished) { create(:contest, :finished) }
    let!(:draft) { create(:contest, :draft) }
    let!(:deleted) { create(:contest, :published, :deleted) }

    it "returns published and finished contests" do
      get "/api/v1/contests", headers: api_headers(token: api_token.token)

      expect(response).to have_http_status(:ok)
      ids = json_response["data"].map { |c| c["id"] }
      expect(ids).to include(published.id, finished.id)
      expect(ids).not_to include(draft.id)
    end

    it "excludes deleted contests" do
      get "/api/v1/contests", headers: api_headers(token: api_token.token)

      ids = json_response["data"].map { |c| c["id"] }
      expect(ids).not_to include(deleted.id)
    end

    it "paginates results" do
      get "/api/v1/contests", params: { page: 1, per_page: 1 },
          headers: api_headers(token: api_token.token)

      expect(response).to have_http_status(:ok)
      expect(json_response["data"].size).to eq(1)
      expect(json_response["meta"]["total_count"]).to be >= 2
      expect(response.headers["X-Total-Count"]).to be_present
    end

    it "orders by created_at desc" do
      get "/api/v1/contests", headers: api_headers(token: api_token.token)

      dates = json_response["data"].map { |c| c["created_at"] }
      expect(dates).to eq(dates.sort.reverse)
    end
  end

  describe "GET /api/v1/contests/:id" do
    let(:contest) { create(:contest, :published) }

    it "returns contest detail" do
      get "/api/v1/contests/#{contest.id}", headers: api_headers(token: api_token.token)

      expect(response).to have_http_status(:ok)
      expect(json_response["data"]["id"]).to eq(contest.id)
      expect(json_response["data"]["title"]).to eq(contest.title)
      expect(json_response["data"]).to have_key("organizer")
      expect(json_response["data"]).to have_key("entries_count")
    end

    it "returns 404 for draft contest" do
      draft = create(:contest, :draft)
      get "/api/v1/contests/#{draft.id}", headers: api_headers(token: api_token.token)

      expect(response).to have_http_status(:not_found)
      expect(json_response["error"]["code"]).to eq("not_found")
    end

    it "returns 404 for deleted contest" do
      deleted = create(:contest, :published, :deleted)
      get "/api/v1/contests/#{deleted.id}", headers: api_headers(token: api_token.token)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for nonexistent contest" do
      get "/api/v1/contests/999999", headers: api_headers(token: api_token.token)

      expect(response).to have_http_status(:not_found)
      expect(json_response["error"]["code"]).to eq("not_found")
    end
  end
end
