# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Create Entry", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:write_token) { create(:api_token, :with_write_scope, user: user) }
  let(:read_token) { create(:api_token, user: user) }
  let(:contest) { create(:contest, :accepting_entries) }

  describe "POST /api/v1/contests/:contest_id/entries" do
    let(:photo_file) do
      fixture_file_upload(
        Rails.root.join("spec/fixtures/files/test_photo.jpg"),
        "image/jpeg"
      )
    end

    it "creates an entry with write scope" do
      post "/api/v1/contests/#{contest.id}/entries",
           params: { entry: { title: "API投稿", description: "テスト", photo: photo_file } },
           headers: api_headers(token: write_token.token)

      expect(response).to have_http_status(:created)
      expect(json_response["data"]["title"]).to eq("API投稿")
      expect(json_response["data"]["user"]["id"]).to eq(user.id)
    end

    it "returns 403 with read-only token" do
      post "/api/v1/contests/#{contest.id}/entries",
           params: { entry: { title: "API投稿", photo: photo_file } },
           headers: api_headers(token: read_token.token)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for non-accepting contest" do
      finished = create(:contest, :finished)

      post "/api/v1/contests/#{finished.id}/entries",
           params: { entry: { title: "API投稿", photo: photo_file } },
           headers: api_headers(token: write_token.token)

      expect(response).to have_http_status(:not_found)
    end

    it "associates entry with current user" do
      post "/api/v1/contests/#{contest.id}/entries",
           params: { entry: { title: "API投稿", photo: photo_file } },
           headers: api_headers(token: write_token.token)

      expect(Entry.last.user).to eq(user)
    end
  end
end
