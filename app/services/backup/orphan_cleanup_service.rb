# frozen_string_literal: true

module Backup
  class OrphanCleanupService
    CleanupResult = Struct.new(:orphaned_blobs, :orphaned_attachments, :purged_count, keyword_init: true)

    def initialize(dry_run: true)
      @dry_run = dry_run
    end

    def perform
      orphaned_blobs = find_orphaned_blobs
      orphaned_attachments = find_orphaned_attachments
      purged_count = 0

      unless @dry_run
        orphaned_blobs.find_each do |blob|
          blob.purge
          purged_count += 1
        end

        orphaned_attachments.find_each do |attachment|
          attachment.purge
          purged_count += 1
        end
      end

      CleanupResult.new(
        orphaned_blobs: orphaned_blobs.count,
        orphaned_attachments: orphaned_attachments.count,
        purged_count: purged_count
      )
    end

    private

    def find_orphaned_blobs
      ActiveStorage::Blob
        .left_joins(:attachments)
        .where(active_storage_attachments: { id: nil })
        .where("active_storage_blobs.created_at < ?", 1.day.ago)
    end

    def find_orphaned_attachments
      attachment_types = ActiveStorage::Attachment.distinct.pluck(:record_type)

      orphaned_ids = []
      attachment_types.each do |record_type|
        model_class = record_type.safe_constantize
        next unless model_class

        attachments_for_type = ActiveStorage::Attachment.where(record_type: record_type)
        existing_ids = model_class.pluck(:id)

        orphaned = attachments_for_type.where.not(record_id: existing_ids)
        orphaned_ids.concat(orphaned.pluck(:id))
      end

      ActiveStorage::Attachment.where(id: orphaned_ids)
    end
  end
end
