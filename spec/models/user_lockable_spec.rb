# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Lockable", type: :model do
  let(:user) { create(:user, :confirmed, email: "locktest@example.com", password: "password123") }

  describe "lockable attributes" do
    it "has failed_attempts attribute" do
      expect(user).to respond_to(:failed_attempts)
    end

    it "has locked_at attribute" do
      expect(user).to respond_to(:locked_at)
    end

    it "has unlock_token attribute" do
      expect(user).to respond_to(:unlock_token)
    end
  end

  describe "failed attempts tracking" do
    it "tracks failed attempts" do
      user.failed_attempts = 3
      user.save!

      expect(user.failed_attempts).to eq(3)
    end

    it "can increment failed attempts" do
      initial_attempts = user.failed_attempts
      user.failed_attempts += 1
      user.save!

      expect(user.failed_attempts).to eq(initial_attempts + 1)
    end

    it "resets failed attempts" do
      user.failed_attempts = 5
      user.save!

      user.failed_attempts = 0
      user.save!

      expect(user.failed_attempts).to eq(0)
    end
  end

  describe "locked_at attribute" do
    it "can be set to lock the account" do
      user.locked_at = Time.current
      user.save!

      expect(user.locked_at).to be_present
    end

    it "can be cleared to unlock the account" do
      user.locked_at = Time.current
      user.save!

      user.locked_at = nil
      user.save!

      expect(user.locked_at).to be_nil
    end
  end

  describe "access_locked? method" do
    it "returns false when locked_at is nil" do
      user.locked_at = nil

      expect(user.access_locked?).to be false
    end

    it "returns true when locked_at is set and within lock period" do
      user.locked_at = 5.minutes.ago

      expect(user.access_locked?).to be true
    end

    it "returns false when lock has expired" do
      # Devise default unlock_in is 30 minutes
      user.locked_at = 31.minutes.ago

      expect(user.access_locked?).to be false
    end
  end

  describe "authentication state" do
    it "is active for authentication when not locked" do
      user.locked_at = nil

      expect(user.active_for_authentication?).to be true
    end

    it "is locked when locked_at is recent" do
      user.locked_at = Time.current

      expect(user.access_locked?).to be true
    end
  end
end
