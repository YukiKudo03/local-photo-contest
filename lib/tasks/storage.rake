# frozen_string_literal: true

namespace :storage do
  desc "Check Active Storage integrity"
  task check_integrity: :environment do
    puts I18n.t("backup.storage.integrity.starting")

    service = Backup::ActiveStorageIntegrityService.new
    result = service.check

    puts I18n.t("backup.storage.integrity.completed")
    puts "-" * 40
    puts "Total blobs:        #{result.total_blobs}"
    puts "Checked:            #{result.checked}"
    puts "Missing:            #{result.missing}"
    puts "Checksum mismatch:  #{result.checksum_mismatch}"
    puts "Errors:             #{result.errors.length}"

    result.errors.each { |e| puts "  - #{e}" } if result.errors.any?
  end

  desc "Find orphaned Active Storage files (dry run)"
  task find_orphans: :environment do
    puts I18n.t("backup.storage.orphans.starting")

    service = Backup::OrphanCleanupService.new(dry_run: true)
    result = service.perform

    total = result.orphaned_blobs + result.orphaned_attachments
    if total > 0
      puts I18n.t("backup.storage.orphans.found", count: total)
      puts "  Orphaned blobs:       #{result.orphaned_blobs}"
      puts "  Orphaned attachments: #{result.orphaned_attachments}"
    else
      puts I18n.t("backup.storage.orphans.none")
    end
  end

  desc "Clean up orphaned Active Storage files"
  task cleanup_orphans: :environment do
    # First show what would be deleted
    dry_service = Backup::OrphanCleanupService.new(dry_run: true)
    dry_result = dry_service.perform

    total = dry_result.orphaned_blobs + dry_result.orphaned_attachments
    if total == 0
      puts I18n.t("backup.storage.orphans.none")
      exit 0
    end

    puts I18n.t("backup.storage.orphans.found", count: total)
    print I18n.t("backup.storage.cleanup.confirm") + " "
    confirmation = $stdin.gets&.strip
    unless confirmation == "yes"
      puts I18n.t("backup.storage.cleanup.cancelled")
      exit 0
    end

    service = Backup::OrphanCleanupService.new(dry_run: false)
    result = service.perform

    puts I18n.t("backup.storage.cleanup.completed", count: result.purged_count)
  end
end
