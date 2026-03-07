# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backup::DatabaseBackupService do
  let(:service) { described_class.new(backup_type: "daily") }
  let(:backup_dir) { Rails.root.join("tmp", "backups") }

  before do
    FileUtils.mkdir_p(backup_dir)
  end

  after do
    FileUtils.rm_rf(backup_dir)
  end

  describe "#perform" do
    context "with SQLite adapter" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:adapter_name).and_return("SQLite")
      end

      it "creates a backup record and compressed dump file" do
        # Stub sqlite3 backup command
        allow(service).to receive(:system).with("sqlite3", anything, anything).and_return(true)

        # Create a fake dump file that the compress step expects
        allow(service).to receive(:create_dump) do
          dump_path = backup_dir.join("backup_test.sqlite3")
          File.write(dump_path, "fake sqlite data")
          dump_path
        end

        result = service.perform

        expect(result.to_s).to end_with(".gz")
        expect(File.exist?(result)).to be true

        record = service.backup_record
        expect(record).to be_completed
        expect(record.backup_type).to eq("daily")
        expect(record.file_size).to be > 0
        expect(record.checksum).to start_with("sha256:")
        expect(record.storage_location).to eq("local")
        expect(record.started_at).to be_present
        expect(record.completed_at).to be_present

        FileUtils.rm_f(result)
      end
    end

    context "with PostgreSQL adapter" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:adapter_name).and_return("PostgreSQL")
        allow(ActiveRecord::Base.connection_db_config).to receive(:configuration_hash).and_return({
          adapter: "postgresql",
          database: "local_photo_contest_production",
          host: "localhost",
          username: "postgres",
          password: "secret"
        })
      end

      it "creates a backup record using pg_dump" do
        allow(service).to receive(:create_dump) do
          dump_path = backup_dir.join("backup_test.sql")
          File.write(dump_path, "fake pg dump data")
          dump_path
        end

        result = service.perform

        expect(result.to_s).to end_with(".gz")
        record = service.backup_record
        expect(record).to be_completed
        expect(record.database_name).to eq("local_photo_contest_production")

        FileUtils.rm_f(result)
      end
    end

    context "when backup fails" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:adapter_name).and_return("SQLite")
      end

      it "marks the backup record as failed and re-raises" do
        allow(service).to receive(:create_dump).and_raise(RuntimeError, "backup command failed")

        expect { service.perform }.to raise_error(RuntimeError, "backup command failed")

        record = service.backup_record
        expect(record).to be_failed
        expect(record.error_message).to eq("backup command failed")
        expect(record.completed_at).to be_present
      end
    end

    it "accepts different backup types" do
      service = described_class.new(backup_type: "weekly")

      allow(ActiveRecord::Base.connection).to receive(:adapter_name).and_return("SQLite")
      allow(service).to receive(:create_dump) do
        dump_path = backup_dir.join("backup_test.sqlite3")
        File.write(dump_path, "fake data")
        dump_path
      end

      result = service.perform

      expect(service.backup_record.backup_type).to eq("weekly")

      FileUtils.rm_f(result)
    end
  end

  describe "#backup_type" do
    it "defaults to daily" do
      service = described_class.new
      expect(service.backup_type).to eq("daily")
    end
  end
end
