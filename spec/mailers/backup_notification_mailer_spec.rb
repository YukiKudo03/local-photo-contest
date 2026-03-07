# frozen_string_literal: true

require "rails_helper"

RSpec.describe BackupNotificationMailer, type: :mailer do
  let(:admin) { create(:user, :confirmed, role: :admin) }

  before do
    admin # ensure admin exists
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("BACKUP_NOTIFY_EMAILS").and_return(nil)
  end

  describe "#backup_completed" do
    let(:backup_record) { create(:backup_record, :completed) }
    let(:mail) { described_class.backup_completed(backup_record) }

    it "sends to admin users" do
      expect(mail.to).to include(admin.email)
    end

    it "sets the correct subject" do
      expect(mail.subject).to include("バックアップ完了")
    end

    it "includes backup details in body" do
      expect(mail.html_part.body.to_s).to include(backup_record.filename)
      expect(mail.html_part.body.to_s).to include(backup_record.database_name)
    end

    context "with BACKUP_NOTIFY_EMAILS env var" do
      before do
        allow(ENV).to receive(:[]).with("BACKUP_NOTIFY_EMAILS").and_return("ops@example.com, dev@example.com")
      end

      it "sends to specified emails" do
        expect(mail.to).to eq([ "ops@example.com", "dev@example.com" ])
      end
    end
  end

  describe "#backup_failed" do
    let(:backup_record) { create(:backup_record, :failed) }
    let(:mail) { described_class.backup_failed(backup_record) }

    it "sends to admin users" do
      expect(mail.to).to include(admin.email)
    end

    it "sets the correct subject" do
      expect(mail.subject).to include("バックアップ失敗")
    end

    it "includes error message in body" do
      expect(mail.html_part.body.to_s).to include(backup_record.error_message)
    end
  end

  describe "#storage_maintenance_report" do
    let(:integrity_result) do
      Struct.new(:total_blobs, :checked, :missing, :checksum_mismatch, :errors, keyword_init: true)
        .new(total_blobs: 100, checked: 95, missing: 2, checksum_mismatch: 1, errors: [ "blob 123: file not found" ])
    end

    let(:cleanup_result) do
      Struct.new(:orphaned_blobs, :orphaned_attachments, :purged_count, keyword_init: true)
        .new(orphaned_blobs: 3, orphaned_attachments: 1, purged_count: 4)
    end

    let(:mail) { described_class.storage_maintenance_report(integrity_result, cleanup_result) }

    it "sends to admin users" do
      expect(mail.to).to include(admin.email)
    end

    it "sets the correct subject" do
      expect(mail.subject).to include("ストレージメンテナンス")
    end

    it "includes integrity check results" do
      body = mail.html_part.body.to_s
      expect(body).to include("100")
      expect(body).to include("95")
    end

    it "includes cleanup results" do
      body = mail.html_part.body.to_s
      expect(body).to include("3")
      expect(body).to include("4")
    end
  end
end
