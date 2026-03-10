# frozen_string_literal: true

require "rails_helper"

RSpec.describe EntryNotifications, type: :model do
  describe "callback error handling" do
    let(:contest) { create(:contest, :published) }

    it "does not raise when broadcast_new_entry_notification fails" do
      allow(NotificationBroadcaster).to receive(:new_entry).and_raise(StandardError, "broadcast error")
      expect { create(:entry, contest: contest) }.not_to raise_error
    end

    it "does not raise when send_entry_submitted_email fails" do
      allow(NotificationMailer).to receive(:entry_submitted).and_raise(StandardError, "mail error")
      expect { create(:entry, contest: contest) }.not_to raise_error
    end

    it "does not raise when clear_statistics_cache fails" do
      allow(StatisticsService).to receive(:clear_cache).and_raise(StandardError, "cache error")
      expect { create(:entry, contest: contest) }.not_to raise_error
    end

    it "does not raise when notify_followers fails" do
      allow(FollowedUserEntryNotificationJob).to receive(:perform_later).and_raise(StandardError, "job error")
      expect { create(:entry, contest: contest) }.not_to raise_error
    end

    it "does not raise when enqueue_exif_extraction fails" do
      allow(ExifExtractionJob).to receive(:perform_later).and_raise(StandardError, "job error")
      expect { create(:entry, contest: contest) }.not_to raise_error
    end

    it "does not raise when enqueue_image_analysis fails" do
      allow(ImageAnalysisJob).to receive(:perform_later).and_raise(StandardError, "analysis error")
      expect { create(:entry, contest: contest) }.not_to raise_error
    end
  end
end
