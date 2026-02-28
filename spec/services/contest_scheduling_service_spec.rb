# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContestSchedulingService do
  let(:organizer) { create(:user, :organizer, :confirmed) }

  describe "#publish!" do
    let(:contest) { create(:contest, :past_scheduled_publish, user: organizer) }
    let(:service) { described_class.new(contest) }

    it "transitions contest from draft to published" do
      service.publish!
      expect(contest.reload).to be_published
    end

    it "broadcasts status change" do
      expect(NotificationBroadcaster).to receive(:contest_status_change).with(contest, :published)
      service.publish!
    end

    it "creates audit log entry" do
      expect { service.publish! }.to change(AuditLog, :count).by(1)
      log = AuditLog.last
      expect(log.action).to eq("contest_auto_publish")
      expect(log.target_type).to eq("Contest")
      expect(log.target_id).to eq(contest.id)
    end

    context "when contest cannot be published (no title)" do
      before { contest.update_column(:title, "") }

      it "raises error" do
        expect { service.publish! }.to raise_error(RuntimeError, /Cannot publish/)
      end
    end
  end

  describe "#finish!" do
    let(:contest) { create(:contest, :past_scheduled_finish, user: organizer) }
    let(:service) { described_class.new(contest) }

    it "transitions contest from published to finished" do
      service.finish!
      expect(contest.reload).to be_finished
    end

    it "broadcasts status change" do
      expect(NotificationBroadcaster).to receive(:contest_status_change).with(contest, :finished)
      service.finish!
    end

    it "creates audit log entry" do
      expect { service.finish! }.to change(AuditLog, :count).by(1)
      log = AuditLog.last
      expect(log.action).to eq("contest_auto_finish")
    end
  end
end
