# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContestArchiveService, type: :service do
  let(:organizer) { create(:user, :organizer, :confirmed) }

  describe "#archive!" do
    let(:contest) { create(:contest, :finished, user: organizer, results_announced_at: 1.day.ago) }

    it "sets archived_at on the contest" do
      described_class.new(contest).archive!
      expect(contest.reload.archived_at).to be_present
    end

    it "creates an audit log" do
      expect {
        described_class.new(contest).archive!
      }.to change(AuditLog, :count).by(1)

      log = AuditLog.last
      expect(log.action).to eq("contest_auto_archive")
      expect(log.target).to eq(contest)
    end

    it "sends notification email to organizer" do
      expect {
        described_class.new(contest).archive!
      }.to have_enqueued_mail(NotificationMailer, :contest_archived)
    end

    it "raises error when contest is not archivable" do
      contest = create(:contest, :published, user: organizer)
      expect { described_class.new(contest).archive! }.to raise_error(RuntimeError)
    end
  end

  describe "#unarchive!" do
    let(:contest) { create(:contest, :archived, user: organizer) }

    it "clears archived_at" do
      described_class.new(contest).unarchive!
      expect(contest.reload.archived_at).to be_nil
    end

    it "creates an audit log" do
      expect {
        described_class.new(contest).unarchive!
      }.to change(AuditLog, :count).by(1)

      log = AuditLog.last
      expect(log.action).to eq("contest_unarchive")
    end
  end
end
