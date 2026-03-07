# frozen_string_literal: true

begin
  require "aws-sdk-s3"
rescue LoadError
  # AWS SDK will be loaded when the gem is installed
end

module Backup
  class S3BackupStorageService
    def initialize
      @daily_retention = ENV.fetch("BACKUP_DAILY_RETENTION", 7).to_i
      @weekly_retention = ENV.fetch("BACKUP_WEEKLY_RETENTION", 4).to_i
    end

    def upload(file_path, backup_type:)
      key = s3_key(backup_type, File.basename(file_path))

      File.open(file_path.to_s, "rb") do |f|
        s3_client.put_object(
          bucket: bucket_name,
          key: key,
          body: f,
          storage_class: "STANDARD_IA",
          server_side_encryption: "AES256"
        )
      end

      { bucket: bucket_name, key: key }
    end

    def download(s3_key, destination)
      FileUtils.mkdir_p(File.dirname(destination))

      s3_client.get_object(
        bucket: bucket_name,
        key: s3_key,
        response_target: destination.to_s
      )

      Pathname.new(destination)
    end

    def list(backup_type: nil)
      prefix = backup_type ? "backups/#{backup_type}/" : "backups/"

      response = s3_client.list_objects_v2(
        bucket: bucket_name,
        prefix: prefix
      )

      response.contents.map do |obj|
        {
          key: obj.key,
          size: obj.size,
          last_modified: obj.last_modified
        }
      end
    end

    def prune
      pruned = []

      %w[daily weekly].each do |type|
        retention = type == "daily" ? @daily_retention : @weekly_retention
        objects = list(backup_type: type).sort_by { |o| o[:last_modified] }.reverse

        objects_to_delete = objects[retention..]
        next unless objects_to_delete&.any?

        objects_to_delete.each do |obj|
          s3_client.delete_object(bucket: bucket_name, key: obj[:key])
          pruned << obj[:key]
        end
      end

      pruned
    end

    def available?
      bucket_name.present? && defined?(Aws::S3) ? true : false
    end

    private

    def s3_key(backup_type, filename)
      "backups/#{backup_type}/#{filename}"
    end

    def bucket_name
      ENV["BACKUP_S3_BUCKET"] || Rails.application.credentials.dig(:backup, :s3_backup_bucket)
    end

    def s3_client
      @s3_client ||= Aws::S3::Client.new(region: aws_region)
    end

    def aws_region
      ENV.fetch("AWS_REGION", "ap-northeast-1")
    end
  end
end
