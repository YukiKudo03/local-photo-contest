# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuditLog, type: :model do
  let(:user) { create(:user, :confirmed) }
  let(:target_user) { create(:user, :confirmed) }

  describe "validations" do
    it "requires action" do
      log = AuditLog.new(user: user)
      expect(log).not_to be_valid
      expect(log.errors[:action]).to be_present
    end

    it "requires valid action" do
      log = AuditLog.new(user: user, action: "invalid_action")
      expect(log).not_to be_valid
      expect(log.errors[:action]).to be_present
    end

    it "accepts valid action" do
      log = AuditLog.new(user: user, action: "login")
      expect(log).to be_valid
    end
  end

  describe ".log" do
    it "creates a new audit log entry" do
      expect {
        AuditLog.log(
          action: "role_change",
          user: user,
          target: target_user,
          details: { old_role: "participant", new_role: "organizer" },
          ip_address: "192.168.1.1"
        )
      }.to change(AuditLog, :count).by(1)
    end

    it "stores the correct attributes" do
      log = AuditLog.log(
        action: "account_suspend",
        user: user,
        target: target_user,
        details: { reason: "Violation" },
        ip_address: "10.0.0.1"
      )

      expect(log.action).to eq("account_suspend")
      expect(log.user).to eq(user)
      expect(log.target_type).to eq("User")
      expect(log.target_id).to eq(target_user.id)
      expect(log.details).to eq({ "reason" => "Violation" })
      expect(log.ip_address).to eq("10.0.0.1")
    end
  end

  describe "#action_name" do
    it "returns human readable action name" do
      log = AuditLog.new(action: "login")
      expect(log.action_name).to eq("Login")
    end
  end

  describe "#target" do
    it "returns the target object if it exists" do
      log = AuditLog.create!(
        action: "role_change",
        user: user,
        target_type: "User",
        target_id: target_user.id
      )

      expect(log.target).to eq(target_user)
    end

    it "returns nil if target is deleted" do
      log = AuditLog.create!(
        action: "role_change",
        user: user,
        target_type: "User",
        target_id: 99999
      )

      expect(log.target).to be_nil
    end

    it "returns nil if target_type is invalid class" do
      log = AuditLog.create!(
        action: "role_change",
        user: user,
        target_type: "NonExistentClass",
        target_id: 1
      )

      expect(log.target).to be_nil
    end
  end

  describe "scopes" do
    before do
      AuditLog.log(action: "login", user: user)
      AuditLog.log(action: "logout", user: user)
      AuditLog.log(action: "login", user: target_user)
    end

    describe ".by_action" do
      it "filters by action" do
        expect(AuditLog.by_action("login").count).to eq(2)
      end
    end

    describe ".by_user" do
      it "filters by user" do
        expect(AuditLog.by_user(user).count).to eq(2)
      end
    end

    describe ".recent" do
      it "orders by created_at desc" do
        expect(AuditLog.recent.first.action).to eq("login")
      end
    end
  end
end
