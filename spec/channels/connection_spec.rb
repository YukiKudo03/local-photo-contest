# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  describe "#connect" do
    it "rejects connection when no user is authenticated" do
      expect { connect "/cable", env: { "warden" => double(user: nil) } }.to have_rejected_connection
    end

    it "successfully connects when user is authenticated" do
      user = create(:user, :confirmed)
      connect "/cable", env: { "warden" => double(user: user) }
      expect(connection.current_user).to eq(user)
    end
  end
end
