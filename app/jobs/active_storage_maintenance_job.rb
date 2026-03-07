# frozen_string_literal: true

class ActiveStorageMaintenanceJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 2

  def perform
    integrity_service = Backup::ActiveStorageIntegrityService.new
    integrity_result = integrity_service.check

    cleanup_service = Backup::OrphanCleanupService.new(dry_run: false)
    cleanup_result = cleanup_service.perform

    BackupNotificationMailer.storage_maintenance_report(integrity_result, cleanup_result).deliver_later
  rescue => e
    Sentry.capture_exception(e) if defined?(Sentry)
    raise
  end
end
