# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API Rate Limiting", type: :request do
  describe "Rack::Attack API throttle configuration" do
    it "includes API token throttle" do
      expect(Rack::Attack.throttles).to have_key("api/token")
    end

    it "includes API IP throttle" do
      expect(Rack::Attack.throttles).to have_key("api/ip")
    end
  end
end
