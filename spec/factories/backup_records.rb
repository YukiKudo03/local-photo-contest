# frozen_string_literal: true

FactoryBot.define do
  factory :backup_record do
    backup_type { "daily" }
    database_name { "local_photo_contest" }
    status { :pending }

    trait :in_progress do
      status { :in_progress }
      started_at { Time.current }
    end

    trait :completed do
      status { :completed }
      filename { "backup_20260307_033000.sql.gz" }
      file_size { 1_048_576 }
      checksum { "sha256:abc123def456" }
      storage_location { "local" }
      started_at { 5.minutes.ago }
      completed_at { Time.current }
    end

    trait :failed do
      status { :failed }
      started_at { 5.minutes.ago }
      completed_at { Time.current }
      error_message { "pg_dump failed with exit code 1" }
    end

    trait :with_s3 do
      storage_location { "s3" }
      s3_bucket { "my-backup-bucket" }
      s3_key { "backups/daily/backup_20260307_033000.sql.gz" }
    end

    trait :encrypted do
      encrypted { true }
      filename { "backup_20260307_033000.sql.gz.enc" }
    end
  end
end
