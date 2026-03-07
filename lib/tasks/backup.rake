# frozen_string_literal: true

namespace :backup do
  desc "Run manual database backup"
  task database: :environment do
    backup_type = ENV.fetch("TYPE", "manual")
    puts I18n.t("backup.rake.database.starting", type: backup_type)

    service = Backup::DatabaseBackupService.new(backup_type: backup_type)
    compressed_path = service.perform

    record = service.backup_record
    puts I18n.t("backup.rake.database.completed",
      filename: record.filename,
      size: ActionController::Base.helpers.number_to_human_size(record.file_size))

    # Encrypt if available
    encryption_service = Backup::BackupEncryptionService.new
    if encryption_service.encryption_available?
      encrypted_path = encryption_service.encrypt(compressed_path)
      record.update!(encrypted: true, filename: File.basename(encrypted_path))
      compressed_path = encrypted_path
    end

    # Upload to S3 if available
    s3_service = Backup::S3BackupStorageService.new
    if s3_service.available?
      result = s3_service.upload(compressed_path, backup_type: backup_type)
      record.update!(storage_location: "s3", s3_bucket: result[:bucket], s3_key: result[:key])
      puts "Uploaded to S3: #{result[:key]}"
    end
  rescue => e
    puts I18n.t("backup.rake.database.failed", error: e.message)
    exit 1
  end

  desc "Restore database from backup file"
  task :restore, [ :file_path ] => :environment do |_t, args|
    file_path = args[:file_path]

    unless file_path && File.exist?(file_path)
      puts I18n.t("backup.rake.restore.file_not_found", file: file_path)
      exit 1
    end

    print I18n.t("backup.rake.restore.confirm") + " "
    confirmation = $stdin.gets&.strip
    unless confirmation == "yes"
      puts I18n.t("backup.rake.restore.cancelled")
      exit 0
    end

    puts I18n.t("backup.rake.restore.starting", file: file_path)

    restore_path = file_path

    # Decrypt if encrypted
    if file_path.end_with?(".enc")
      encryption_service = Backup::BackupEncryptionService.new
      restore_path = encryption_service.decrypt(file_path).to_s
    end

    # Decompress if gzipped
    if restore_path.end_with?(".gz")
      decompressed_path = restore_path.sub(/\.gz\z/, "")
      Zlib::GzipReader.open(restore_path) do |gz|
        File.open(decompressed_path, "wb") { |f| f.write(gz.read) }
      end
      restore_path = decompressed_path
    end

    config = ActiveRecord::Base.connection_db_config.configuration_hash
    adapter = ActiveRecord::Base.connection.adapter_name.downcase

    if adapter.include?("postgresql")
      env = {}
      env["PGPASSWORD"] = config[:password] if config[:password].present?

      cmd = [ "pg_restore", "--no-owner", "--no-acl", "--clean", "--if-exists" ]
      cmd += [ "-h", config[:host] ] if config[:host].present?
      cmd += [ "-p", config[:port].to_s ] if config[:port].present?
      cmd += [ "-U", config[:username] ] if config[:username].present?
      cmd += [ "-d", config[:database] ]
      cmd << restore_path

      success = system(env, *cmd)
      raise "pg_restore failed" unless success
    else
      db_path = config[:database]
      success = system("sqlite3", db_path, ".restore '#{restore_path}'")
      raise "sqlite3 restore failed" unless success
    end

    puts I18n.t("backup.rake.restore.completed")
  rescue => e
    puts I18n.t("backup.rake.restore.failed", error: e.message)
    exit 1
  end

  desc "Download backup from S3"
  task :download, [ :s3_key ] => :environment do |_t, args|
    s3_key = args[:s3_key]
    destination = Rails.root.join("tmp", "backups", File.basename(s3_key))
    FileUtils.mkdir_p(File.dirname(destination))

    service = Backup::S3BackupStorageService.new
    service.download(s3_key, destination)

    puts I18n.t("backup.rake.download.completed", destination: destination)
  rescue => e
    puts I18n.t("backup.rake.download.failed", error: e.message)
    exit 1
  end

  desc "List backup records"
  task list: :environment do
    puts I18n.t("backup.rake.list.title")
    puts "-" * 80

    records = BackupRecord.recent.limit(20)
    if records.empty?
      puts I18n.t("backup.rake.list.no_records")
    else
      records.each do |record|
        status_mark = case record.status
        when "completed" then "[OK]"
        when "failed" then "[NG]"
        when "in_progress" then "[..]"
        else "[--]"
        end

        puts format("%-6s %-8s %-8s %-40s %s",
          status_mark,
          record.backup_type,
          record.storage_location || "local",
          record.filename || "-",
          record.created_at.strftime("%Y-%m-%d %H:%M"))
      end
    end
  end

  desc "Prune old backups from S3"
  task prune: :environment do
    service = Backup::S3BackupStorageService.new
    pruned = service.prune

    if pruned.any?
      puts I18n.t("backup.rake.prune.completed", count: pruned.length)
    else
      puts I18n.t("backup.rake.prune.no_pruning")
    end
  end
end
