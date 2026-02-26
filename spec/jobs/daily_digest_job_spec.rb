# frozen_string_literal: true

require "rails_helper"

RSpec.describe DailyDigestJob, type: :job do
  describe "#perform" do
    let(:organizer) { create(:user, :organizer, :confirmed) }
    let(:contest) { create(:contest, :published, user: organizer) }

    context "with new entries from yesterday" do
      before do
        create(:entry, contest: contest, created_at: 1.day.ago)
      end

      it "sends digest email for organizer" do
        expect {
          described_class.perform_now
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end

    context "with no new entries" do
      it "does not send any emails" do
        expect {
          described_class.perform_now
        }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context "when organizer has email_digest disabled" do
      before do
        organizer.update!(email_digest: false)
        create(:entry, contest: contest, created_at: 1.day.ago)
      end

      it "does not send email" do
        expect {
          described_class.perform_now
        }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end
  end
end
