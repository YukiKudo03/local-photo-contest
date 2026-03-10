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
          port: 5432,
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

      it "calls pg_dump with correct arguments including host, port, username, and password" do
        expect(service).to receive(:system) do |env, *cmd|
          expect(env).to eq({ "PGPASSWORD" => "secret" })
          expect(cmd).to include("pg_dump", "--no-owner", "--no-acl", "-Fc")
          expect(cmd).to include("-h", "localhost")
          expect(cmd).to include("-p", "5432")
          expect(cmd).to include("-U", "postgres")
          expect(cmd).to include("local_photo_contest_production")
          # Simulate creating the dump file
          f_idx = cmd.index("-f")
          File.write(cmd[f_idx + 1], "fake pg dump") if f_idx
          true
        end

        result = service.perform
        FileUtils.rm_f(result)
      end

      it "raises when pg_dump fails" do
        allow(service).to receive(:system) do |*_args|
          system("exit 1")
          false
        end

        expect { service.perform }.to raise_error(RuntimeError, /pg_dump failed/)
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

    context "ensure cleanup of temp dump file" do
      before do
        allow(ActiveRecord::Base.connection).to receive(:adapter_name).and_return("SQLite")
      end

      it "removes the uncompressed dump file after successful backup" do
        dump_path = backup_dir.join("backup_cleanup_test.sqlite3")
        allow(service).to receive(:create_dump) do
          File.write(dump_path, "fake data for cleanup test")
          dump_path
        end

        result = service.perform

        expect(File.exist?(dump_path)).to be false
        FileUtils.rm_f(result)
      end

      it "removes the uncompressed dump file even when backup fails" do
        dump_path = backup_dir.join("backup_fail_cleanup.sqlite3")
        allow(service).to receive(:create_dump) do
          File.write(dump_path, "fake data")
          dump_path
        end
        allow(service).to receive(:compress).and_raise(RuntimeError, "compress failed")

        expect { service.perform }.to raise_error(RuntimeError, "compress failed")
        expect(File.exist?(dump_path)).to be false
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

  describe "execute_sqlite_backup" do
    before do
      allow(ActiveRecord::Base.connection).to receive(:adapter_name).and_return("SQLite")
    end

    it "executes sqlite3 backup command and creates dump file" do
      db_config = ActiveRecord::Base.connection_db_config.configuration_hash
      db_path = db_config[:database]

      allow(service).to receive(:system).with("sqlite3", db_path, anything) do |_cmd, _db, backup_arg|
        # Extract dump path from backup command and create a fake file
        dump_path = backup_arg.match(/\.backup '(.+)'/)[1]
        File.write(dump_path, "fake sqlite data")
        true
      end

      result = service.perform
      expect(result.to_s).to end_with(".gz")
      FileUtils.rm_f(result)
    end

    it "raises when sqlite3 backup command fails" do
      allow(service).to receive(:system).with("sqlite3", anything, anything) do
        system("exit 1")
        false
      end

      expect { service.perform }.to raise_error(RuntimeError, /sqlite3 backup failed/)
    end
  end
end
