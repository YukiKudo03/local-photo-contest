# frozen_string_literal: true

require "openssl"

module Backup
  class BackupEncryptionService
    ALGORITHM = "aes-256-gcm"
    IV_LENGTH = 12
    AUTH_TAG_LENGTH = 16

    def encrypt(file_path)
      key = encryption_key
      raise "Backup encryption key not configured" unless key

      cipher = OpenSSL::Cipher.new(ALGORITHM)
      cipher.encrypt
      cipher.key = [ key ].pack("H*")
      iv = cipher.random_iv

      encrypted_path = "#{file_path}.enc"

      File.open(encrypted_path, "wb") do |out|
        out.write(iv)

        File.open(file_path.to_s, "rb") do |f|
          while (chunk = f.read(1024 * 1024))
            out.write(cipher.update(chunk))
          end
        end

        out.write(cipher.final)
        out.write(cipher.auth_tag(AUTH_TAG_LENGTH))
      end

      Pathname.new(encrypted_path)
    end

    def decrypt(encrypted_path)
      key = encryption_key
      raise "Backup encryption key not configured" unless key

      data = File.binread(encrypted_path.to_s)

      iv = data[0, IV_LENGTH]
      auth_tag = data[-AUTH_TAG_LENGTH, AUTH_TAG_LENGTH]
      ciphertext = data[IV_LENGTH..-(AUTH_TAG_LENGTH + 1)]

      cipher = OpenSSL::Cipher.new(ALGORITHM)
      cipher.decrypt
      cipher.key = [ key ].pack("H*")
      cipher.iv = iv
      cipher.auth_tag = auth_tag

      decrypted_path = encrypted_path.to_s.sub(/\.enc\z/, "")

      File.open(decrypted_path, "wb") do |out|
        out.write(cipher.update(ciphertext))
        out.write(cipher.final)
      end

      Pathname.new(decrypted_path)
    end

    def encryption_available?
      encryption_key.present?
    end

    private

    def encryption_key
      Rails.application.credentials.dig(:backup, :encryption_key)
    end
  end
end
