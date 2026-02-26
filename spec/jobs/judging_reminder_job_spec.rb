# frozen_string_literal: true

require "rails_helper"

RSpec.describe JudgingReminderJob, type: :job do
  describe "#perform" do
    let(:contest) { create(:contest, :published, judging_method: :judge_only) }
    let(:judge_user) { create(:user, :confirmed) }
    let!(:contest_judge) { create(:contest_judge, contest: contest, user: judge_user) }

    before do
      contest.update_column(:status, Contest.statuses[:finished])
    end

    context "with unfinished judging" do
      it "enqueues reminder email" do
        expect {
          described_class.perform_now
        }.to have_enqueued_mail(NotificationMailer, :judging_reminder)
      end
    end

    context "when results are already announced" do
      before do
        contest.update_column(:results_announced_at, Time.current)
      end

      it "does not enqueue email" do
        expect {
          described_class.perform_now
        }.not_to have_enqueued_mail(NotificationMailer, :judging_reminder)
      end
    end
  end
end
