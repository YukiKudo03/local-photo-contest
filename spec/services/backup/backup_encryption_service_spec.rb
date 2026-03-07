# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backup::BackupEncryptionService do
  let(:service) { described_class.new }
  let(:test_key) { OpenSSL::Random.random_bytes(32).unpack1("H*") }
  let(:tmp_dir) { Rails.root.join("tmp", "test_encryption") }

  before do
    FileUtils.mkdir_p(tmp_dir)
    allow(Rails.application.credentials).to receive(:dig)
      .with(:backup, :encryption_key).and_return(test_key)
  end

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  describe "#encrypt" do
    it "creates an encrypted file" do
      original_path = tmp_dir.join("test_backup.sql.gz")
      File.write(original_path, "database dump content")

      encrypted_path = service.encrypt(original_path)

      expect(encrypted_path.to_s).to end_with(".enc")
      expect(File.exist?(encrypted_path)).to be true
      expect(File.binread(encrypted_path)).not_to eq("database dump content")
    end

    it "raises error when encryption key is not configured" do
      allow(Rails.application.credentials).to receive(:dig)
        .with(:backup, :encryption_key).and_return(nil)

      original_path = tmp_dir.join("test_backup.sql.gz")
      File.write(original_path, "data")

      expect { service.encrypt(original_path) }.to raise_error("Backup encryption key not configured")
    end
  end

  describe "#decrypt" do
    it "decrypts an encrypted file back to original content" do
      original_path = tmp_dir.join("test_backup.sql.gz")
      original_content = "This is a test database dump with some data: #{SecureRandom.hex(100)}"
      File.write(original_path, original_content)

      encrypted_path = service.encrypt(original_path)

      # Remove original to ensure decrypt produces it
      FileUtils.rm_f(original_path)

      decrypted_path = service.decrypt(encrypted_path)

      expect(File.read(decrypted_path)).to eq(original_content)
    end

    it "raises error with wrong key" do
      original_path = tmp_dir.join("test_backup.sql.gz")
      File.write(original_path, "secret data")

      encrypted_path = service.encrypt(original_path)

      # Change key
      wrong_key = OpenSSL::Random.random_bytes(32).unpack1("H*")
      allow(Rails.application.credentials).to receive(:dig)
        .with(:backup, :encryption_key).and_return(wrong_key)

      expect { service.decrypt(encrypted_path) }.to raise_error(OpenSSL::Cipher::CipherError)
    end
  end

  describe "#encryption_available?" do
    it "returns true when key is configured" do
      expect(service.encryption_available?).to be true
    end

    it "returns false when key is not configured" do
      allow(Rails.application.credentials).to receive(:dig)
        .with(:backup, :encryption_key).and_return(nil)
      expect(service.encryption_available?).to be false
    end
  end
end
