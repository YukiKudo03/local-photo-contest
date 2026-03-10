# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApiToken, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }

    context "uniqueness" do
      subject { create(:api_token) }
      it { is_expected.to validate_uniqueness_of(:token) }
    end
  end

  describe "token generation" do
    it "generates a token before creation" do
      token = build(:api_token, token: nil)
      token.valid?
      expect(token.token).to be_present
    end

    it "does not overwrite an existing token" do
      token = create(:api_token)
      original = token.token
      token.valid?
      expect(token.token).to eq(original)
    end
  end

  describe "#active?" do
    it "returns true for non-revoked, non-expired token" do
      token = build(:api_token)
      expect(token.active?).to be true
    end

    it "returns false for revoked token" do
      token = build(:api_token, revoked_at: Time.current)
      expect(token.active?).to be false
    end

    it "returns false for expired token" do
      token = build(:api_token, expires_at: 1.day.ago)
      expect(token.active?).to be false
    end

    it "returns true for future expiry" do
      token = build(:api_token, expires_at: 1.day.from_now)
      expect(token.active?).to be true
    end
  end

  describe "#revoke!" do
    it "sets revoked_at" do
      token = create(:api_token)
      token.revoke!
      expect(token.reload.revoked_at).to be_present
    end
  end

  describe "#touch_last_used!" do
    it "updates last_used_at" do
      token = create(:api_token)
      token.touch_last_used!
      expect(token.reload.last_used_at).to be_present
    end
  end

  describe "scopes" do
    describe ".active" do
      it "excludes revoked tokens" do
        active = create(:api_token)
        create(:api_token, :revoked)
        expect(ApiToken.active).to contain_exactly(active)
      end

      it "excludes expired tokens" do
        active = create(:api_token)
        create(:api_token, :expired)
        expect(ApiToken.active).to contain_exactly(active)
      end
    end
  end

  describe "#parsed_scopes" do
    it "parses JSON string scopes" do
      token = build(:api_token)
      token.scopes = '["read","write"]'
      expect(token.parsed_scopes).to eq(["read", "write"])
    end

    it "returns array directly when scopes is an Array" do
      token = build(:api_token)
      token.scopes = ["read", "write"]
      expect(token.parsed_scopes).to eq(["read", "write"])
    end

    it "returns default [read] when scopes is nil" do
      token = build(:api_token, scopes: nil)
      expect(token.parsed_scopes).to eq(["read"])
    end

    it "returns default [read] on JSON parse error" do
      token = build(:api_token)
      token.scopes = "not valid json{"
      expect(token.parsed_scopes).to eq(["read"])
    end
  end

  describe "#scope?" do
    it "returns true for included scope" do
      token = build(:api_token, :with_write_scope)
      expect(token.scope?("write")).to be true
    end

    it "returns false for missing scope" do
      token = build(:api_token)
      expect(token.scope?("write")).to be false
    end
  end
end
