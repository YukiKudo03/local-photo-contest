# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContestAutoArchiveJob, type: :job do
  include ActiveJob::TestHelper

  let(:organizer) { create(:user, :organizer, :confirmed) }

  describe "#perform" do
    context "when contest exceeds auto_archive_days" do
      let!(:contest) { create(:contest, :archivable, user: organizer) }

      it "archives the contest" do
        described_class.perform_now
        expect(contest.reload.archived?).to be true
      end

      it "sends notification to organizer" do
        expect {
          described_class.perform_now
        }.to have_enqueued_mail(NotificationMailer, :contest_archived)
      end
    end

    context "when contest is within auto_archive_days" do
      let!(:contest) do
        create(:contest, :finished, user: organizer,
               results_announced_at: 10.days.ago, auto_archive_days: 90)
      end

      it "does not archive the contest" do
        described_class.perform_now
        expect(contest.reload.archived?).to be false
      end
    end

    context "when auto_archive_days is nil (opt-out)" do
      let!(:contest) do
        create(:contest, :finished, user: organizer,
               results_announced_at: 100.days.ago, auto_archive_days: nil)
      end

      it "does not archive the contest" do
        described_class.perform_now
        expect(contest.reload.archived?).to be false
      end
    end

    context "when contest is already archived" do
      let!(:contest) { create(:contest, :archived, user: organizer) }

      it "does not re-archive" do
        original_archived_at = contest.archived_at
        described_class.perform_now
        expect(contest.reload.archived_at).to eq(original_archived_at)
      end
    end

    context "when one contest fails" do
      let!(:contest1) { create(:contest, :archivable, user: organizer) }
      let!(:contest2) { create(:contest, :archivable, user: organizer) }

      it "continues processing other contests" do
        call_count = 0
        allow_any_instance_of(ContestArchiveService).to receive(:archive!).and_wrap_original do |method, *args|
          call_count += 1
          raise "Simulated error" if call_count == 1
          method.call(*args)
        end

        described_class.perform_now
        archived_count = [contest1, contest2].count { |c| c.reload.archived? }
        expect(archived_count).to eq(1)
      end
    end
  end
end
