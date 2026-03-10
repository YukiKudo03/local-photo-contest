# frozen_string_literal: true

require "rails_helper"

RSpec.describe GraduatedJudgingReminderJob, type: :job do
  include ActiveJob::TestHelper

  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:judge_user) { create(:user, :confirmed) }

  describe "#perform" do
    context "3 days before deadline (first reminder)" do
      let(:contest) do
        create(:contest, :accepting_entries, user: organizer, judging_method: :judge_only)
      end
      let!(:criterion) { create(:evaluation_criterion, contest: contest) }
      let!(:entry) { create(:entry, contest: contest) }
      let!(:cj) { create(:contest_judge, contest: contest, user: judge_user) }

      before do
        contest.finish!
        contest.update_column(:judging_deadline_at, 3.days.from_now)
      end

      it "sends warning-level reminder email" do
        expect {
          described_class.perform_now
        }.to have_enqueued_mail(NotificationMailer, :graduated_judging_reminder)
      end

      it "increments reminder_count" do
        described_class.perform_now
        expect(cj.reload.reminder_count).to eq(1)
      end
    end

    context "when judge has completed all evaluations" do
      let(:contest) do
        create(:contest, :accepting_entries, user: organizer, judging_method: :judge_only)
      end
      let!(:criterion) { create(:evaluation_criterion, contest: contest) }
      let!(:entry) { create(:entry, contest: contest) }
      let!(:cj) { create(:contest_judge, contest: contest, user: judge_user) }

      before do
        contest.finish!
        contest.update_column(:judging_deadline_at, 3.days.from_now)
        create(:judge_evaluation, contest_judge: cj, entry: entry, evaluation_criterion: criterion)
      end

      it "does not send any reminders" do
        expect {
          described_class.perform_now
        }.not_to have_enqueued_mail(NotificationMailer, :graduated_judging_reminder)
      end
    end

    context "when results are already announced" do
      let(:contest) do
        create(:contest, :accepting_entries, user: organizer, judging_method: :judge_only)
      end
      let!(:criterion) { create(:evaluation_criterion, contest: contest) }
      let!(:entry) { create(:entry, contest: contest) }
      let!(:cj) { create(:contest_judge, contest: contest, user: judge_user) }

      before do
        contest.finish!
        contest.update_columns(judging_deadline_at: 3.days.from_now, results_announced_at: Time.current)
      end

      it "does not send any reminders" do
        expect {
          described_class.perform_now
        }.not_to have_enqueued_mail(NotificationMailer, :graduated_judging_reminder)
      end
    end

    context "when contest uses vote_only judging" do
      let(:contest) do
        create(:contest, :accepting_entries, user: organizer, judging_method: :vote_only)
      end
      let!(:cj) { create(:contest_judge, contest: contest, user: judge_user) }

      before do
        contest.finish!
        contest.update_column(:judging_deadline_at, 3.days.from_now)
      end

      it "does not send reminders" do
        expect {
          described_class.perform_now
        }.not_to have_enqueued_mail(NotificationMailer, :graduated_judging_reminder)
      end
    end

    context "when processing a judge fails" do
      let(:contest) do
        create(:contest, :accepting_entries, user: organizer, judging_method: :judge_only)
      end
      let!(:criterion) { create(:evaluation_criterion, contest: contest) }
      let!(:entry) { create(:entry, contest: contest) }
      let!(:cj) { create(:contest_judge, contest: contest, user: judge_user) }

      before do
        contest.finish!
        contest.update_column(:judging_deadline_at, 3.days.from_now)
        allow(NotificationMailer).to receive(:graduated_judging_reminder).and_raise(StandardError, "mail error")
      end

      it "logs error and continues" do
        expect(Rails.logger).to receive(:error).with(/Graduated reminder failed/)
        expect { described_class.perform_now }.not_to raise_error
      end
    end

    context "deadline day (final reminder) with escalation" do
      let(:contest) do
        create(:contest, :accepting_entries, user: organizer, judging_method: :judge_only)
      end
      let!(:criterion) { create(:evaluation_criterion, contest: contest) }
      let!(:entry) { create(:entry, contest: contest) }
      let!(:cj) do
        cj = create(:contest_judge, contest: contest, user: judge_user)
        cj.update!(reminder_count: 2, last_reminder_sent_at: 1.day.ago)
        cj
      end

      before do
        contest.finish!
        contest.update_column(:judging_deadline_at, Time.current.end_of_day)
      end

      it "sends final reminder and escalation to organizer" do
        expect {
          described_class.perform_now
        }.to have_enqueued_mail(NotificationMailer, :graduated_judging_reminder)
                .and have_enqueued_mail(NotificationMailer, :judging_escalation)
      end
    end
  end
end
