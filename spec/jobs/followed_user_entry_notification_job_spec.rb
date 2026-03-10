# frozen_string_literal: true

require "rails_helper"

RSpec.describe FollowedUserEntryNotificationJob, type: :job do
  describe "#perform" do
    let(:contest) { create(:contest, :published) }
    let(:entry_user) { create(:user, :confirmed) }
    let(:entry) { create(:entry, user: entry_user, contest: contest) }

    context "with an entry that has followers" do
      let!(:follow1) { create(:follow, followed: entry_user) }
      let!(:follow2) { create(:follow, followed: entry_user) }

      it "creates notifications for each follower" do
        expect {
          described_class.perform_now(entry.id)
        }.to change(Notification, :count).by(2)
      end

      it "creates notifications with correct attributes" do
        described_class.perform_now(entry.id)

        notification = Notification.find_by(user: follow1.follower)
        expect(notification).to be_present
        expect(notification.notifiable).to eq(entry)
        expect(notification.notification_type).to eq("followed_user_entry")
      end

      it "broadcasts to each follower" do
        expect(NotificationBroadcaster).to receive(:followed_user_new_entry).with(entry, follow1.follower)
        expect(NotificationBroadcaster).to receive(:followed_user_new_entry).with(entry, follow2.follower)

        described_class.perform_now(entry.id)
      end

      it "sends email when email is enabled" do
        expect {
          described_class.perform_now(entry.id)
        }.to have_enqueued_mail(NotificationMailer, :followed_user_entry).at_least(:once)
      end
    end

    context "when entry is not found" do
      it "returns early without creating notifications" do
        expect {
          described_class.perform_now(-1)
        }.not_to change(Notification, :count)
      end
    end

    context "when email is disabled for a follower" do
      let!(:follow) { create(:follow, followed: entry_user) }

      before do
        follow.follower.update!(email_on_followed_entry: false)
      end

      it "does not send email" do
        expect {
          described_class.perform_now(entry.id)
        }.not_to have_enqueued_mail(NotificationMailer, :followed_user_entry)
      end

      it "still creates notification" do
        expect {
          described_class.perform_now(entry.id)
        }.to change(Notification, :count).by(1)
      end
    end

    context "when error occurs for one follower" do
      let!(:follow1) { create(:follow, followed: entry_user) }
      let!(:follow2) { create(:follow, followed: entry_user) }

      it "continues processing other followers" do
        call_count = 0
        allow(Notification).to receive(:create!).and_wrap_original do |method, **args|
          call_count += 1
          if call_count == 1
            raise StandardError, "test error"
          else
            method.call(**args)
          end
        end

        expect(Rails.logger).to receive(:error).with(/FollowedUserEntryNotificationJob/)

        described_class.perform_now(entry.id)

        expect(Notification.count).to eq(1)
      end
    end
  end
end
