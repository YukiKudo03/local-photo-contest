# frozen_string_literal: true

require "zlib"
require "digest"

module Backup
  class DatabaseBackupService
    attr_reader :backup_type, :backup_record

    def initialize(backup_type: "daily")
      @backup_type = backup_type
    end

    def perform
      @backup_record = BackupRecord.create!(
        backup_type: backup_type,
        database_name: database_name,
        status: :in_progress,
        started_at: Time.current
      )

      dump_path = create_dump
      compressed_path = compress(dump_path)
      checksum = calculate_checksum(compressed_path)

      @backup_record.update!(
        status: :completed,
        filename: File.basename(compressed_path),
        file_size: File.size(compressed_path),
        checksum: "sha256:#{checksum}",
        storage_location: "local",
        completed_at: Time.current
      )

      compressed_path
    rescue => e
      @backup_record&.update!(
        status: :failed,
        error_message: e.message,
        completed_at: Time.current
      )
      raise
    ensure
      FileUtils.rm_f(dump_path) if dump_path && File.exist?(dump_path.to_s)
    end

    private

    def create_dump
      FileUtils.mkdir_p(backup_dir)
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")

      if postgresql?
        dump_path = backup_dir.join("backup_#{timestamp}.sql")
        execute_pg_dump(dump_path)
      else
        dump_path = backup_dir.join("backup_#{timestamp}.sqlite3")
        execute_sqlite_backup(dump_path)
      end

      dump_path
    end

    def compress(dump_path)
      compressed_path = Pathname.new("#{dump_path}.gz")

      Zlib::GzipWriter.open(compressed_path.to_s) do |gz|
        File.open(dump_path.to_s, "rb") do |f|
          while (chunk = f.read(1024 * 1024))
            gz.write(chunk)
          end
        end
      end

      compressed_path
    end

    def calculate_checksum(file_path)
      Digest::SHA256.file(file_path.to_s).hexdigest
    end

    def execute_pg_dump(dump_path)
      config = database_config
      env = {}
      env["PGPASSWORD"] = config[:password] if config[:password].present?

      cmd = [ "pg_dump", "--no-owner", "--no-acl", "-Fc" ]
      cmd += [ "-h", config[:host] ] if config[:host].present?
      cmd += [ "-p", config[:port].to_s ] if config[:port].present?
      cmd += [ "-U", config[:username] ] if config[:username].present?
      cmd += [ "-f", dump_path.to_s ]
      cmd << config[:database]

      success = system(env, *cmd)
      raise "pg_dump failed with exit code #{$?.exitstatus}" unless success
    end

    def execute_sqlite_backup(dump_path)
      db_path = database_config[:database]
      success = system("sqlite3", db_path, ".backup '#{dump_path}'")
      raise "sqlite3 backup failed with exit code #{$?.exitstatus}" unless success
    end

    def postgresql?
      adapter_name.include?("postgresql") || adapter_name.include?("postgis")
    end

    def adapter_name
      ActiveRecord::Base.connection.adapter_name.downcase
    end

    def database_config
      ActiveRecord::Base.connection_db_config.configuration_hash
    end

    def database_name
      config = database_config
      config[:database] || "unknown"
    end

    def backup_dir
      Rails.root.join("tmp", "backups")
    end
  end
end
