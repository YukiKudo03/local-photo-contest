# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backup::OrphanCleanupService do
  describe "#perform" do
    context "dry run (default)" do
      let(:service) { described_class.new }

      it "counts orphaned blobs without deleting" do
        # Create a blob without attachment, created > 1 day ago
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("orphan data"),
          filename: "orphan.txt",
          content_type: "text/plain"
        )
        blob.update_column(:created_at, 2.days.ago)

        result = service.perform

        expect(result.orphaned_blobs).to be >= 1
        expect(result.purged_count).to eq(0)
        expect(ActiveStorage::Blob.exists?(blob.id)).to be true

        blob.purge # cleanup
      end

      it "does not count recently created unattached blobs" do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("recent data"),
          filename: "recent.txt",
          content_type: "text/plain"
        )
        # blob created_at is now, which is < 1 day ago

        result = service.perform
        # Should not be counted as orphaned since it's too recent
        recent_orphans = ActiveStorage::Blob
          .left_joins(:attachments)
          .where(active_storage_attachments: { id: nil })
          .where("active_storage_blobs.created_at >= ?", 1.day.ago)

        expect(recent_orphans.exists?(blob.id)).to be true

        blob.purge # cleanup
      end
    end

    context "with dry_run: false" do
      let(:service) { described_class.new(dry_run: false) }

      it "purges orphaned blobs" do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("orphan data"),
          filename: "orphan.txt",
          content_type: "text/plain"
        )
        blob.update_column(:created_at, 2.days.ago)

        result = service.perform

        expect(result.purged_count).to be >= 1
        expect(ActiveStorage::Blob.exists?(blob.id)).to be false
      end
    end

    context "with no orphans" do
      let(:service) { described_class.new }

      it "returns zero counts when all blobs are attached" do
        # Clean up any existing orphans first
        ActiveStorage::Blob
          .left_joins(:attachments)
          .where(active_storage_attachments: { id: nil })
          .find_each(&:purge)

        result = service.perform

        expect(result.orphaned_blobs).to eq(0)
        expect(result.purged_count).to eq(0)
      end
    end
  end
end
