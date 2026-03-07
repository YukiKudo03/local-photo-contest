# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backup::S3BackupStorageService do
  let(:service) { described_class.new }
  let(:s3_client) { instance_double(Aws::S3::Client) }
  let(:bucket_name) { "test-backup-bucket" }
  let(:tmp_dir) { Rails.root.join("tmp", "test_s3") }

  before do
    FileUtils.mkdir_p(tmp_dir)
    allow(Aws::S3::Client).to receive(:new).and_return(s3_client)
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("BACKUP_S3_BUCKET").and_return(bucket_name)
  end

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  describe "#upload" do
    it "uploads a file to S3 with STANDARD_IA storage class" do
      file_path = tmp_dir.join("test_backup.sql.gz")
      File.write(file_path, "backup data")

      expect(s3_client).to receive(:put_object).with(
        bucket: bucket_name,
        key: "backups/daily/test_backup.sql.gz",
        body: instance_of(File),
        storage_class: "STANDARD_IA",
        server_side_encryption: "AES256"
      )

      result = service.upload(file_path, backup_type: "daily")

      expect(result[:bucket]).to eq(bucket_name)
      expect(result[:key]).to eq("backups/daily/test_backup.sql.gz")
    end

    it "uses correct S3 key for weekly backups" do
      file_path = tmp_dir.join("weekly_backup.sql.gz")
      File.write(file_path, "data")

      expect(s3_client).to receive(:put_object).with(hash_including(
        key: "backups/weekly/weekly_backup.sql.gz"
      ))

      service.upload(file_path, backup_type: "weekly")
    end
  end

  describe "#download" do
    it "downloads a file from S3" do
      destination = tmp_dir.join("downloaded_backup.sql.gz")

      expect(s3_client).to receive(:get_object).with(
        bucket: bucket_name,
        key: "backups/daily/test.sql.gz",
        response_target: destination.to_s
      )

      result = service.download("backups/daily/test.sql.gz", destination)
      expect(result).to be_a(Pathname)
    end
  end

  describe "#list" do
    let(:s3_objects) do
      [
        double(key: "backups/daily/backup_1.sql.gz", size: 1000, last_modified: 1.day.ago),
        double(key: "backups/daily/backup_2.sql.gz", size: 2000, last_modified: Time.current)
      ]
    end

    it "lists objects with backup_type prefix" do
      allow(s3_client).to receive(:list_objects_v2)
        .with(bucket: bucket_name, prefix: "backups/daily/")
        .and_return(double(contents: s3_objects))

      results = service.list(backup_type: "daily")

      expect(results.length).to eq(2)
      expect(results.first[:key]).to eq("backups/daily/backup_1.sql.gz")
    end

    it "lists all objects when no backup_type specified" do
      allow(s3_client).to receive(:list_objects_v2)
        .with(bucket: bucket_name, prefix: "backups/")
        .and_return(double(contents: s3_objects))

      results = service.list
      expect(results.length).to eq(2)
    end
  end

  describe "#prune" do
    it "deletes backups exceeding retention count" do
      daily_objects = (1..10).map do |i|
        double(key: "backups/daily/backup_#{i}.sql.gz", size: 1000, last_modified: i.days.ago)
      end

      weekly_objects = (1..6).map do |i|
        double(key: "backups/weekly/backup_#{i}.sql.gz", size: 1000, last_modified: i.weeks.ago)
      end

      allow(s3_client).to receive(:list_objects_v2)
        .with(bucket: bucket_name, prefix: "backups/daily/")
        .and_return(double(contents: daily_objects))

      allow(s3_client).to receive(:list_objects_v2)
        .with(bucket: bucket_name, prefix: "backups/weekly/")
        .and_return(double(contents: weekly_objects))

      # Daily: 10 objects, retain 7 → delete 3
      # Weekly: 6 objects, retain 4 → delete 2
      expect(s3_client).to receive(:delete_object).exactly(5).times

      pruned = service.prune
      expect(pruned.length).to eq(5)
    end

    it "does nothing when within retention limits" do
      daily_objects = (1..3).map do |i|
        double(key: "backups/daily/backup_#{i}.sql.gz", size: 1000, last_modified: i.days.ago)
      end

      allow(s3_client).to receive(:list_objects_v2)
        .with(bucket: bucket_name, prefix: "backups/daily/")
        .and_return(double(contents: daily_objects))

      allow(s3_client).to receive(:list_objects_v2)
        .with(bucket: bucket_name, prefix: "backups/weekly/")
        .and_return(double(contents: []))

      expect(s3_client).not_to receive(:delete_object)

      pruned = service.prune
      expect(pruned).to be_empty
    end
  end

  describe "#available?" do
    it "returns true when bucket name is configured" do
      expect(service.available?).to be true
    end

    it "returns false when bucket name is not configured" do
      allow(ENV).to receive(:[]).with("BACKUP_S3_BUCKET").and_return(nil)
      allow(Rails.application.credentials).to receive(:dig)
        .with(:backup, :s3_backup_bucket).and_return(nil)
      expect(service.available?).to be false
    end
  end
end
