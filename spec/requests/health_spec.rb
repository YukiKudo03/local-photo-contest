# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Health Check", type: :request do
  describe "GET /health" do
    it "returns success status" do
      get "/health"

      expect(response).to have_http_status(:ok)
    end

    it "returns JSON response" do
      get "/health"

      expect(response.content_type).to include("application/json")
    end

    it "includes database status" do
      get "/health"

      json = JSON.parse(response.body)
      expect(json["database"]).to eq("ok")
    end

    it "includes timestamp" do
      get "/health"

      json = JSON.parse(response.body)
      expect(json["timestamp"]).to be_present
    end

    it "includes overall status" do
      get "/health"

      json = JSON.parse(response.body)
      expect(json["status"]).to eq("ok")
    end

    context "when database is unavailable" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(ActiveRecord::ConnectionNotEstablished)
      end

      it "returns error status" do
        get "/health"

        json = JSON.parse(response.body)
        expect(json["database"]).to eq("error")
        expect(json["status"]).to eq("error")
      end
    end
  end

  describe "GET /health/details" do
    it "returns detailed health information" do
      get "/health/details"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["database"]).to be_present
      expect(json["cache"]).to be_present
      expect(json["version"]).to be_present
    end

    it "includes database connection count" do
      get "/health/details"

      json = JSON.parse(response.body)
      expect(json["database"]["connected"]).to be true
    end

    context "when database connection fails" do
      before do
        allow(ActiveRecord::Base).to receive(:connection).and_raise(ActiveRecord::ConnectionNotEstablished)
      end

      it "returns error details for database" do
        get "/health/details"

        json = JSON.parse(response.body)
        expect(json["database"]["connected"]).to be false
        expect(json["database"]["error"]).to be_present
      end
    end

    context "when cache connection fails" do
      it "returns unhealthy cache status" do
        cache_double = instance_double(ActiveSupport::Cache::MemoryStore)
        allow(cache_double).to receive(:class).and_return(ActiveSupport::Cache::MemoryStore)
        allow(cache_double).to receive(:write).and_raise(StandardError, "cache error")
        allow(Rails).to receive(:cache).and_return(cache_double)

        get "/health/details"

        json = JSON.parse(response.body)
        expect(json["cache"]["healthy"]).to be false
      end
    end
  end
end
