# frozen_string_literal: true

require "rails_helper"

RSpec.describe DatabaseBackupJob, type: :job do
  let(:backup_record) { create(:backup_record, :completed) }
  let(:backup_service) { instance_double(Backup::DatabaseBackupService) }
  let(:encryption_service) { instance_double(Backup::BackupEncryptionService) }
  let(:s3_service) { instance_double(Backup::S3BackupStorageService) }
  let(:compressed_path) { Pathname.new("/tmp/test_backup.sql.gz") }

  before do
    allow(Backup::DatabaseBackupService).to receive(:new).and_return(backup_service)
    allow(Backup::BackupEncryptionService).to receive(:new).and_return(encryption_service)
    allow(Backup::S3BackupStorageService).to receive(:new).and_return(s3_service)

    allow(backup_service).to receive(:perform).and_return(compressed_path)
    allow(backup_service).to receive(:backup_record).and_return(backup_record)
    allow(encryption_service).to receive(:encryption_available?).and_return(false)
    allow(s3_service).to receive(:available?).and_return(false)

    allow(FileUtils).to receive(:rm_f)
    allow(BackupNotificationMailer).to receive_message_chain(:backup_completed, :deliver_later)
  end

  describe "#perform" do
    it "runs database backup and sends notification" do
      described_class.perform_now("daily")

      expect(backup_service).to have_received(:perform)
      expect(BackupNotificationMailer).to have_received(:backup_completed).with(backup_record)
    end

    it "encrypts when encryption is available" do
      encrypted_path = Pathname.new("/tmp/test_backup.sql.gz.enc")
      allow(encryption_service).to receive(:encryption_available?).and_return(true)
      allow(encryption_service).to receive(:encrypt).with(compressed_path).and_return(encrypted_path)

      described_class.perform_now("daily")

      expect(encryption_service).to have_received(:encrypt)
      expect(backup_record.encrypted).to be true
    end

    it "uploads to S3 when available and prunes old backups" do
      allow(s3_service).to receive(:available?).and_return(true)
      allow(s3_service).to receive(:upload).and_return({ bucket: "test", key: "backups/daily/test.sql.gz" })
      allow(s3_service).to receive(:prune)

      described_class.perform_now("daily")

      expect(s3_service).to have_received(:upload)
      expect(s3_service).to have_received(:prune)
      expect(backup_record.storage_location).to eq("s3")
    end

    it "passes backup_type to service" do
      expect(Backup::DatabaseBackupService).to receive(:new).with(backup_type: "weekly")
      described_class.perform_now("weekly")
    end

    context "when backup fails" do
      before do
        allow(backup_service).to receive(:perform).and_raise(RuntimeError, "pg_dump failed")
        allow(BackupNotificationMailer).to receive_message_chain(:backup_failed, :deliver_later)
      end

      it "sends failure notification" do
        # retry_on catches the error, so perform_now won't raise
        described_class.perform_now("daily")
        expect(BackupNotificationMailer).to have_received(:backup_failed).with(backup_record)
      end
    end

    it "cleans up temporary files" do
      described_class.perform_now("daily")
      expect(FileUtils).to have_received(:rm_f).with(compressed_path)
    end
  end
end
