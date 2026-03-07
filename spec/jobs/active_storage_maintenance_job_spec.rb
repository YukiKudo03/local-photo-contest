# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorageMaintenanceJob, type: :job do
  let(:integrity_result) do
    Backup::ActiveStorageIntegrityService::IntegrityResult.new(
      total_blobs: 10, checked: 10, missing: 0, checksum_mismatch: 0, errors: []
    )
  end

  let(:cleanup_result) do
    Backup::OrphanCleanupService::CleanupResult.new(
      orphaned_blobs: 0, orphaned_attachments: 0, purged_count: 0
    )
  end

  let(:integrity_service) { instance_double(Backup::ActiveStorageIntegrityService) }
  let(:cleanup_service) { instance_double(Backup::OrphanCleanupService) }

  before do
    allow(Backup::ActiveStorageIntegrityService).to receive(:new).and_return(integrity_service)
    allow(Backup::OrphanCleanupService).to receive(:new).with(dry_run: false).and_return(cleanup_service)
    allow(integrity_service).to receive(:check).and_return(integrity_result)
    allow(cleanup_service).to receive(:perform).and_return(cleanup_result)
    allow(BackupNotificationMailer).to receive_message_chain(:storage_maintenance_report, :deliver_later)
  end

  describe "#perform" do
    it "runs integrity check and cleanup" do
      described_class.perform_now

      expect(integrity_service).to have_received(:check)
      expect(cleanup_service).to have_received(:perform)
    end

    it "sends maintenance report notification" do
      described_class.perform_now

      expect(BackupNotificationMailer).to have_received(:storage_maintenance_report)
        .with(integrity_result, cleanup_result)
    end

    it "runs cleanup with dry_run: false" do
      described_class.perform_now

      expect(Backup::OrphanCleanupService).to have_received(:new).with(dry_run: false)
    end
  end
end
