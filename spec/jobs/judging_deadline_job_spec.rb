# frozen_string_literal: true

require "rails_helper"

RSpec.describe JudgingDeadlineJob, type: :job do
  describe "#perform" do
    let(:judge_user) { create(:user, :confirmed) }

    context "when 7 days remaining with judge_only contest" do
      let(:contest) do
        create(:contest, :finished, judging_method: :judge_only,
               entry_end_at: 7.days.from_now, results_announced_at: nil)
      end
      let!(:contest_judge) { create(:contest_judge, contest: contest, user: judge_user) }

      before do
        allow(contest_judge).to receive(:evaluation_progress).and_return(50)
      end

      it "sends deadline warning email" do
        expect {
          described_class.perform_now
        }.to have_enqueued_mail(NotificationMailer, :judging_deadline)
      end
    end

    context "when 3 days remaining with hybrid contest" do
      let(:contest) do
        create(:contest, :finished, judging_method: :hybrid,
               entry_end_at: 3.days.from_now, results_announced_at: nil)
      end
      let!(:contest_judge) { create(:contest_judge, contest: contest, user: judge_user) }

      before do
        allow(contest_judge).to receive(:evaluation_progress).and_return(50)
      end

      it "sends deadline warning email" do
        expect {
          described_class.perform_now
        }.to have_enqueued_mail(NotificationMailer, :judging_deadline)
      end
    end

    context "when non-warning day (5 days remaining)" do
      let(:contest) do
        create(:contest, :finished, judging_method: :judge_only,
               entry_end_at: 5.days.from_now, results_announced_at: nil)
      end
      let!(:contest_judge) { create(:contest_judge, contest: contest, user: judge_user) }

      it "does not send email" do
        expect {
          described_class.perform_now
        }.not_to have_enqueued_mail(NotificationMailer, :judging_deadline)
      end
    end

    context "when contest is vote_only" do
      let(:contest) do
        create(:contest, :finished, judging_method: :vote_only,
               entry_end_at: 7.days.from_now, results_announced_at: nil)
      end
      let!(:contest_judge) { create(:contest_judge, contest: contest, user: judge_user) }

      it "does not send email" do
        expect {
          described_class.perform_now
        }.not_to have_enqueued_mail(NotificationMailer, :judging_deadline)
      end
    end

    context "when judge has evaluation_progress of 100" do
      let(:contest) do
        create(:contest, :finished, judging_method: :judge_only,
               entry_end_at: 7.days.from_now, results_announced_at: nil)
      end
      let!(:contest_judge) { create(:contest_judge, contest: contest, user: judge_user) }

      before do
        allow_any_instance_of(ContestJudge).to receive(:evaluation_progress).and_return(100)
      end

      it "skips the judge" do
        expect {
          described_class.perform_now
        }.not_to have_enqueued_mail(NotificationMailer, :judging_deadline)
      end
    end

    context "when results_announced_at is set" do
      let(:contest) do
        create(:contest, :finished, judging_method: :judge_only,
               entry_end_at: 7.days.from_now, results_announced_at: Time.current)
      end
      let!(:contest_judge) { create(:contest_judge, contest: contest, user: judge_user) }

      it "skips the contest" do
        expect {
          described_class.perform_now
        }.not_to have_enqueued_mail(NotificationMailer, :judging_deadline)
      end
    end
  end
end
