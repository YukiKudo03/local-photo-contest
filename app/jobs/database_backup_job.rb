# frozen_string_literal: true

class DatabaseBackupJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 2

  def perform(backup_type = "daily")
    backup_service = Backup::DatabaseBackupService.new(backup_type: backup_type)
    compressed_path = backup_service.perform
    backup_record = backup_service.backup_record

    file_path = compressed_path

    # Encrypt if key is configured
    encryption_service = Backup::BackupEncryptionService.new
    if encryption_service.encryption_available?
      file_path = encryption_service.encrypt(compressed_path)
      backup_record.update!(encrypted: true, filename: File.basename(file_path))
    end

    # Upload to S3 if configured
    s3_service = Backup::S3BackupStorageService.new
    if s3_service.available?
      result = s3_service.upload(file_path, backup_type: backup_type)
      backup_record.update!(
        storage_location: "s3",
        s3_bucket: result[:bucket],
        s3_key: result[:key]
      )
      s3_service.prune
    end

    BackupNotificationMailer.backup_completed(backup_record).deliver_later
  rescue => e
    backup_record = backup_service&.backup_record
    if backup_record&.persisted?
      BackupNotificationMailer.backup_failed(backup_record).deliver_later
    end

    Sentry.capture_exception(e) if defined?(Sentry)
    raise
  ensure
    FileUtils.rm_f(compressed_path) if compressed_path
    FileUtils.rm_f(file_path) if file_path && file_path != compressed_path
  end
end
