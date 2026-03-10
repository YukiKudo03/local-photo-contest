# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeletionReminderJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform" do
    it "sends reminder to users 7 days before deletion" do
      create(:user, :confirmed,
             deletion_requested_at: 23.days.ago,
             deletion_scheduled_at: 7.days.from_now)

      expect {
        described_class.perform_now
      }.to have_enqueued_mail(AccountDeletionMailer, :deletion_reminder)
    end

    it "does not send reminder to users more than 7 days from deletion" do
      create(:user, :confirmed,
             deletion_requested_at: 10.days.ago,
             deletion_scheduled_at: 20.days.from_now)

      expect {
        described_class.perform_now
      }.not_to have_enqueued_mail(AccountDeletionMailer, :deletion_reminder)
    end

    it "does not send reminder to users without deletion request" do
      create(:user, :confirmed)

      expect {
        described_class.perform_now
      }.not_to have_enqueued_mail(AccountDeletionMailer, :deletion_reminder)
    end

    it "continues processing when one user fails" do
      create(:user, :confirmed,
             deletion_requested_at: 23.days.ago,
             deletion_scheduled_at: 7.days.from_now)

      allow(AccountDeletionMailer).to receive(:deletion_reminder).and_raise(StandardError, "mail error")
      expect(Rails.logger).to receive(:error).with(/Deletion reminder failed/)
      expect { described_class.perform_now }.not_to raise_error
    end
  end
end
