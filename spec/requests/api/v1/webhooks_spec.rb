# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Webhooks", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:write_token) { create(:api_token, :with_write_scope, user: user) }

  describe "GET /api/v1/webhooks" do
    it "returns only own webhooks" do
      own = create(:webhook, user: user)
      other = create(:webhook)

      get "/api/v1/webhooks", headers: api_headers(token: write_token.token)

      expect(response).to have_http_status(:ok)
      ids = json_response["data"].map { |w| w["id"] }
      expect(ids).to include(own.id)
      expect(ids).not_to include(other.id)
    end
  end

  describe "GET /api/v1/webhooks/:id" do
    it "returns webhook details" do
      webhook = create(:webhook, user: user)

      get "/api/v1/webhooks/#{webhook.id}",
          headers: api_headers(token: write_token.token)

      expect(response).to have_http_status(:ok)
      expect(json_response["data"]["id"]).to eq(webhook.id)
    end
  end

  describe "POST /api/v1/webhooks" do
    it "creates a webhook" do
      params = {
        webhook: {
          url: "https://example.com/hook",
          event_types: [ "entry.created", "vote.created" ]
        }
      }

      post "/api/v1/webhooks", params: params.to_json,
           headers: api_headers(token: write_token.token)

      expect(response).to have_http_status(:created)
      expect(json_response["data"]["url"]).to eq("https://example.com/hook")
    end

    it "returns 422 for invalid URL" do
      params = { webhook: { url: "http://example.com/hook", event_types: [ "entry.created" ] } }

      post "/api/v1/webhooks", params: params.to_json,
           headers: api_headers(token: write_token.token)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 for invalid events" do
      params = { webhook: { url: "https://example.com/hook", event_types: [ "invalid" ] } }

      post "/api/v1/webhooks", params: params.to_json,
           headers: api_headers(token: write_token.token)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/webhooks/:id" do
    it "updates own webhook" do
      webhook = create(:webhook, user: user)

      patch "/api/v1/webhooks/#{webhook.id}",
            params: { webhook: { url: "https://new.example.com/hook" } }.to_json,
            headers: api_headers(token: write_token.token)

      expect(response).to have_http_status(:ok)
      expect(webhook.reload.url).to eq("https://new.example.com/hook")
    end

    it "returns 404 for other users webhook" do
      other_webhook = create(:webhook)

      patch "/api/v1/webhooks/#{other_webhook.id}",
            params: { webhook: { url: "https://evil.com/hook" } }.to_json,
            headers: api_headers(token: write_token.token)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 for invalid update" do
      webhook = create(:webhook, user: user)

      patch "/api/v1/webhooks/#{webhook.id}",
            params: { webhook: { url: "http://invalid.com/hook" } }.to_json,
            headers: api_headers(token: write_token.token)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response["error"]["code"]).to eq("unprocessable_entity")
    end
  end

  describe "DELETE /api/v1/webhooks/:id" do
    it "deletes own webhook" do
      webhook = create(:webhook, user: user)

      expect {
        delete "/api/v1/webhooks/#{webhook.id}",
               headers: api_headers(token: write_token.token)
      }.to change(Webhook, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe "error handling" do
    it "returns 422 for RecordInvalid errors" do
      webhook = create(:webhook, user: user)
      error = ActiveRecord::RecordInvalid.new(webhook)
      allow_any_instance_of(Webhook).to receive(:destroy!).and_raise(error)

      delete "/api/v1/webhooks/#{webhook.id}",
             headers: api_headers(token: write_token.token)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response["error"]["code"]).to eq("unprocessable_entity")
    end
  end

  describe "GET /api/v1/webhooks/:id/deliveries" do
    it "returns delivery history" do
      webhook = create(:webhook, user: user)
      create(:webhook_delivery, :delivered, webhook: webhook)
      create(:webhook_delivery, :failed, webhook: webhook)

      get "/api/v1/webhooks/#{webhook.id}/deliveries",
          headers: api_headers(token: write_token.token)

      expect(response).to have_http_status(:ok)
      expect(json_response["data"].size).to eq(2)
    end
  end
end
