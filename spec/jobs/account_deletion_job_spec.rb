# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountDeletionJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform" do
    let!(:user) do
      create(:user, :confirmed,
             deletion_requested_at: 31.days.ago,
             deletion_scheduled_at: 1.day.ago)
    end

    it "purges users past their scheduled deletion date" do
      described_class.perform_now
      expect(User.find_by(id: user.id)).to be_nil
    end

    it "sends a deletion completed email before purging" do
      expect(AccountDeletionMailer).to receive(:deletion_completed).with(user).and_call_original
      described_class.perform_now
    end

    it "does not purge users before their scheduled deletion date" do
      user.update!(deletion_scheduled_at: 1.day.from_now)
      described_class.perform_now
      expect(User.find_by(id: user.id)).to be_present
    end

    context "when one user fails" do
      let!(:user2) do
        create(:user, :confirmed,
               deletion_requested_at: 31.days.ago,
               deletion_scheduled_at: 1.day.ago)
      end

      it "continues processing other users" do
        call_count = 0
        allow_any_instance_of(UserDataPurgeService).to receive(:purge!).and_wrap_original do |method, *args|
          call_count += 1
          raise "Simulated error" if call_count == 1
          method.call(*args)
        end

        described_class.perform_now
        deleted_count = [user, user2].count { |u| User.find_by(id: u.id).nil? }
        expect(deleted_count).to eq(1)
      end
    end
  end
end
