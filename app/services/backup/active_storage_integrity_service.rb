# frozen_string_literal: true

require "digest"

module Backup
  class ActiveStorageIntegrityService
    IntegrityResult = Struct.new(:total_blobs, :checked, :missing, :checksum_mismatch, :errors, keyword_init: true)

    MAX_CHECKSUM_SIZE = 50.megabytes

    def check
      total = ActiveStorage::Blob.count
      checked = 0
      missing = 0
      checksum_mismatch = 0
      errors = []

      ActiveStorage::Blob.find_each do |blob|
        begin
          unless blob.service.exist?(blob.key)
            missing += 1
            errors << "Blob #{blob.id} (#{blob.filename}): file missing"
            next
          end

          checked += 1

          if blob.byte_size <= MAX_CHECKSUM_SIZE
            verify_checksum(blob, errors) do
              checksum_mismatch += 1
            end
          end
        rescue => e
          errors << "Blob #{blob.id} (#{blob.filename}): #{e.message}"
        end
      end

      IntegrityResult.new(
        total_blobs: total,
        checked: checked,
        missing: missing,
        checksum_mismatch: checksum_mismatch,
        errors: errors
      )
    end

    private

    def verify_checksum(blob, errors)
      blob.open do |tempfile|
        computed = Digest::MD5.file(tempfile.path).base64digest
        unless computed == blob.checksum
          yield
          errors << "Blob #{blob.id} (#{blob.filename}): checksum mismatch (expected #{blob.checksum}, got #{computed})"
        end
      end
    end
  end
end
