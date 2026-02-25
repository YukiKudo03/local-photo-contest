# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rate Limiting", type: :request do
  describe "Rack::Attack configuration" do
    it "is configured with throttle rules" do
      expect(Rack::Attack.throttles).to include("req/ip")
      expect(Rack::Attack.throttles).to include("logins/ip")
      expect(Rack::Attack.throttles).to include("spot_votes/ip")
      expect(Rack::Attack.throttles).to include("entry_votes/ip")
    end

    it "has custom throttled response" do
      expect(Rack::Attack.throttled_responder).to be_present
    end
  end

  describe "spot votes endpoint" do
    let(:user) { create(:user, :confirmed) }
    let(:contest) { create(:contest, :published) }
    let(:spot) { create(:spot, contest: contest) }

    before { sign_in user }

    it "allows normal voting" do
      post spot_spot_vote_path(spot)
      # Should work normally (302 redirect or 200)
      expect(response.status).to be_in([200, 302, 303])
    end
  end

  describe "entry votes endpoint" do
    let(:user) { create(:user, :confirmed) }
    let(:contest) { create(:contest, :published) }
    let(:entry_owner) { create(:user, :confirmed) }
    let(:entry) { create(:entry, user: entry_owner, contest: contest) }

    before { sign_in user }

    it "allows normal voting" do
      post entry_vote_path(entry)
      # Should work normally (302 redirect or 200)
      expect(response.status).to be_in([200, 302, 303])
    end
  end

  describe "login endpoint" do
    let(:user) { create(:user, :confirmed) }

    it "allows login attempts" do
      post user_session_path, params: {
        user: { email: user.email, password: "password123" }
      }
      # Should redirect on successful login (to root or dashboard depending on role)
      expect(response).to have_http_status(:redirect)
    end
  end
end
