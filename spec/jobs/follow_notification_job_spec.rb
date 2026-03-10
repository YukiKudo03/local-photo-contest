# frozen_string_literal: true

require "rails_helper"

RSpec.describe FollowNotificationJob, type: :job do
  describe "#perform" do
    let(:follow) { create(:follow) }

    context "with a valid follow" do
      it "creates a notification for the followed user" do
        expect {
          described_class.perform_now(follow.id)
        }.to change(Notification, :count).by(1)

        notification = Notification.last
        expect(notification.user).to eq(follow.followed)
        expect(notification.notifiable).to eq(follow)
        expect(notification.notification_type).to eq("new_follower")
      end

      it "broadcasts via NotificationBroadcaster" do
        expect(NotificationBroadcaster).to receive(:new_follower).with(follow)

        described_class.perform_now(follow.id)
      end

      it "sends email when email is enabled" do
        allow(follow.followed).to receive(:email_enabled?).with(:new_follower).and_return(true)

        expect {
          described_class.perform_now(follow.id)
        }.to have_enqueued_mail(NotificationMailer, :new_follower)
      end
    end

    context "with an invalid follow_id" do
      it "returns early without creating notification" do
        expect {
          described_class.perform_now(-1)
        }.not_to change(Notification, :count)
      end
    end

    context "when email is disabled" do
      before do
        follow.followed.update!(email_on_new_follower: false)
      end

      it "does not send email" do
        expect {
          described_class.perform_now(follow.id)
        }.not_to have_enqueued_mail(NotificationMailer, :new_follower)
      end

      it "still creates notification" do
        expect {
          described_class.perform_now(follow.id)
        }.to change(Notification, :count).by(1)
      end
    end

    context "when an error occurs" do
      before do
        allow(Follow).to receive(:find_by).and_return(follow)
        allow(Notification).to receive(:create!).and_raise(StandardError.new("test error"))
      end

      it "logs the error and does not raise" do
        expect(Rails.logger).to receive(:error).with(/FollowNotificationJob.*test error/)

        expect {
          described_class.perform_now(follow.id)
        }.not_to raise_error
      end
    end
  end
end
