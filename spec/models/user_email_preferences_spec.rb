# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User email preferences", type: :model do
  describe "unsubscribe_token" do
    it "generates token on create" do
      user = create(:user, :confirmed)
      expect(user.unsubscribe_token).to be_present
    end

    it "generates unique tokens" do
      user1 = create(:user, :confirmed)
      user2 = create(:user, :confirmed)
      expect(user1.unsubscribe_token).not_to eq(user2.unsubscribe_token)
    end
  end

  describe "#ensure_unsubscribe_token!" do
    it "returns existing token if present" do
      user = create(:user, :confirmed)
      original_token = user.unsubscribe_token
      expect(user.ensure_unsubscribe_token!).to eq(original_token)
    end

    it "generates token if missing" do
      user = create(:user, :confirmed)
      user.update_column(:unsubscribe_token, nil)
      user.reload

      token = user.ensure_unsubscribe_token!
      expect(token).to be_present
      expect(user.reload.unsubscribe_token).to eq(token)
    end
  end

  describe "#email_enabled?" do
    let(:user) { create(:user, :confirmed) }

    it "returns true for enabled preferences" do
      expect(user.email_enabled?(:entry_submitted)).to be true
      expect(user.email_enabled?(:comment)).to be true
      expect(user.email_enabled?(:results)).to be true
    end

    it "returns false for vote by default" do
      expect(user.email_enabled?(:vote)).to be false
    end

    it "returns correct value when changed" do
      user.update!(email_on_comment: false)
      expect(user.email_enabled?(:comment)).to be false
    end

    it "returns true for unknown types" do
      expect(user.email_enabled?(:unknown_type)).to be true
    end
  end

  describe "default values" do
    let(:user) { create(:user, :confirmed) }

    it "has correct defaults" do
      expect(user.email_on_entry_submitted).to be true
      expect(user.email_on_comment).to be true
      expect(user.email_on_vote).to be false
      expect(user.email_on_results).to be true
      expect(user.email_digest).to be true
      expect(user.email_on_judging).to be true
    end
  end
end
