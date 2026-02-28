# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Votes", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:write_token) { create(:api_token, :with_write_scope, user: user) }
  let(:contest) { create(:contest, :accepting_entries) }
  let(:other_user) { create(:user, :confirmed) }
  let(:entry) { create(:entry, contest: contest, user: other_user) }

  describe "POST /api/v1/entries/:id/votes" do
    it "creates a vote with write scope" do
      post "/api/v1/entries/#{entry.id}/votes",
           headers: api_headers(token: write_token.token)

      expect(response).to have_http_status(:created)
    end

    it "returns 422 for duplicate vote" do
      create(:vote, user: user, entry: entry)

      post "/api/v1/entries/#{entry.id}/votes",
           headers: api_headers(token: write_token.token)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 for own entry" do
      own_entry = create(:entry, contest: contest, user: user)

      post "/api/v1/entries/#{own_entry.id}/votes",
           headers: api_headers(token: write_token.token)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/entries/:id/votes" do
    it "removes the vote" do
      create(:vote, user: user, entry: entry)

      delete "/api/v1/entries/#{entry.id}/votes",
             headers: api_headers(token: write_token.token)

      expect(response).to have_http_status(:no_content)
      expect(Vote.where(user: user, entry: entry)).not_to exist
    end

    it "returns 404 when vote does not exist" do
      delete "/api/v1/entries/#{entry.id}/votes",
             headers: api_headers(token: write_token.token)

      expect(response).to have_http_status(:not_found)
    end
  end
end
