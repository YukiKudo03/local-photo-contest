# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContestJudge, type: :model do
  describe "associations" do
    it { should belong_to(:contest) }
    it { should belong_to(:user) }
    it { should have_many(:judge_evaluations).dependent(:destroy) }
    it { should have_many(:judge_comments).dependent(:destroy) }
  end

  describe "validations" do
    let(:contest) { create(:contest, :published) }
    let(:user) { create(:user, :confirmed) }

    it "validates uniqueness of user_id scoped to contest_id" do
      create(:contest_judge, contest: contest, user: user)
      duplicate = build(:contest_judge, contest: contest, user: user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include("は既にこのコンテストの審査員です")
    end

    it "allows same user to be judge for different contests" do
      create(:contest_judge, contest: contest, user: user)
      other_contest = create(:contest, :published)
      other_judge = build(:contest_judge, contest: other_contest, user: user)
      expect(other_judge).to be_valid
    end
  end

  describe "scopes" do
    describe ".for_contest" do
      let(:contest) { create(:contest, :published) }
      let!(:judge1) { create(:contest_judge, contest: contest) }
      let!(:judge2) { create(:contest_judge) }

      it "returns judges for the specified contest" do
        expect(ContestJudge.for_contest(contest)).to eq([ judge1 ])
      end
    end

    describe ".for_user" do
      let(:user) { create(:user, :confirmed) }
      let!(:judge1) { create(:contest_judge, user: user) }
      let!(:judge2) { create(:contest_judge) }

      it "returns judge assignments for the specified user" do
        expect(ContestJudge.for_user(user)).to eq([ judge1 ])
      end
    end
  end

  describe "#evaluated_entry?" do
    let(:contest) { create(:contest, :published) }
    let(:contest_judge) { create(:contest_judge, contest: contest) }
    let(:entry) { create(:entry, contest: contest) }
    let(:criterion) { create(:evaluation_criterion, contest: contest) }

    context "when entry has been evaluated" do
      before do
        create(:judge_evaluation, contest_judge: contest_judge, entry: entry, evaluation_criterion: criterion)
      end

      it "returns true" do
        expect(contest_judge.evaluated_entry?(entry)).to be true
      end
    end

    context "when entry has not been evaluated" do
      it "returns false" do
        expect(contest_judge.evaluated_entry?(entry)).to be false
      end
    end
  end

  describe "#fully_evaluated_entry?" do
    let(:contest) { create(:contest, :published) }
    let(:contest_judge) { create(:contest_judge, contest: contest) }
    let(:entry) { create(:entry, contest: contest) }
    let!(:criterion1) { create(:evaluation_criterion, contest: contest, name: "Criterion1") }
    let!(:criterion2) { create(:evaluation_criterion, contest: contest, name: "Criterion2") }

    context "when all criteria have been evaluated" do
      before do
        create(:judge_evaluation, contest_judge: contest_judge, entry: entry, evaluation_criterion: criterion1)
        create(:judge_evaluation, contest_judge: contest_judge, entry: entry, evaluation_criterion: criterion2)
      end

      it "returns true" do
        expect(contest_judge.fully_evaluated_entry?(entry)).to be true
      end
    end

    context "when some criteria are not evaluated" do
      before do
        create(:judge_evaluation, contest_judge: contest_judge, entry: entry, evaluation_criterion: criterion1)
      end

      it "returns false" do
        expect(contest_judge.fully_evaluated_entry?(entry)).to be false
      end
    end

    context "when no criteria exist" do
      let(:contest_without_criteria) { create(:contest, :published) }
      let(:judge) { create(:contest_judge, contest: contest_without_criteria) }
      let(:entry_in_contest) { create(:entry, contest: contest_without_criteria) }

      it "returns false" do
        expect(judge.fully_evaluated_entry?(entry_in_contest)).to be false
      end
    end
  end

  describe "#evaluation_progress" do
    let(:contest) { create(:contest, :published) }
    let(:contest_judge) { create(:contest_judge, contest: contest) }
    let!(:entry1) { create(:entry, contest: contest) }
    let!(:entry2) { create(:entry, contest: contest) }
    let!(:criterion) { create(:evaluation_criterion, contest: contest) }

    context "when no entries are evaluated" do
      it "returns 0" do
        expect(contest_judge.evaluation_progress).to eq(0)
      end
    end

    context "when half of entries are fully evaluated" do
      before do
        create(:judge_evaluation, contest_judge: contest_judge, entry: entry1, evaluation_criterion: criterion)
      end

      it "returns 50" do
        expect(contest_judge.evaluation_progress).to eq(50)
      end
    end

    context "when all entries are fully evaluated" do
      before do
        create(:judge_evaluation, contest_judge: contest_judge, entry: entry1, evaluation_criterion: criterion)
        create(:judge_evaluation, contest_judge: contest_judge, entry: entry2, evaluation_criterion: criterion)
      end

      it "returns 100" do
        expect(contest_judge.evaluation_progress).to eq(100)
      end
    end
  end

  describe "reminder tracking" do
    let(:organizer) { create(:user, :organizer, :confirmed) }
    let(:judge_user) { create(:user, :confirmed) }

    describe "#effective_deadline" do
      it "returns judging_deadline_at when set" do
        contest = create(:contest, :finished, user: organizer, judging_deadline_at: 3.days.from_now)
        cj = create(:contest_judge, contest: contest, user: judge_user)
        expect(cj.effective_deadline).to eq(contest.judging_deadline_at)
      end

      it "falls back to entry_end_at when judging_deadline_at is nil" do
        contest = create(:contest, :finished, user: organizer,
                         entry_start_at: 2.months.ago, entry_end_at: 3.days.from_now)
        cj = create(:contest_judge, contest: contest, user: judge_user)
        expect(cj.effective_deadline).to eq(contest.entry_end_at)
      end

      it "returns nil when neither is set" do
        contest = create(:contest, :finished, user: organizer)
        cj = create(:contest_judge, contest: contest, user: judge_user)
        expect(cj.effective_deadline).to be_nil
      end
    end

    describe "#needs_reminder?" do
      let(:contest) do
        create(:contest, :accepting_entries, user: organizer, judging_method: :judge_only)
      end
      let!(:criterion) { create(:evaluation_criterion, contest: contest) }
      let!(:entry) { create(:entry, contest: contest) }
      let(:cj) { create(:contest_judge, contest: contest, user: judge_user) }

      before do
        contest.finish!
        contest.update_column(:judging_deadline_at, 3.days.from_now)
      end

      it "returns true when 3 days before deadline and no reminder sent" do
        expect(cj.needs_reminder?).to be true
      end

      it "returns false when reminder already sent for this stage" do
        cj.update!(reminder_count: 1, last_reminder_sent_at: 1.hour.ago)
        expect(cj.needs_reminder?).to be false
      end

      it "returns false when evaluation is 100% complete" do
        create(:judge_evaluation, contest_judge: cj, entry: entry, evaluation_criterion: criterion)
        expect(cj.needs_reminder?).to be false
      end

      it "returns false when no deadline is set" do
        contest.update_column(:judging_deadline_at, nil)
        expect(cj.needs_reminder?).to be false
      end
    end

    describe "#reminder_urgency" do
      let(:contest) { create(:contest, :accepting_entries, user: organizer, judging_method: :judge_only) }
      let!(:criterion) { create(:evaluation_criterion, contest: contest) }
      let!(:entry) { create(:entry, contest: contest) }
      let(:cj) { create(:contest_judge, contest: contest, user: judge_user) }

      before do
        contest.finish!
      end

      it "returns :warning when 3 days before deadline" do
        contest.update_column(:judging_deadline_at, 3.days.from_now)
        expect(cj.reminder_urgency).to eq(:warning)
      end

      it "returns :urgent when 1 day before deadline" do
        contest.update_column(:judging_deadline_at, 1.day.from_now)
        expect(cj.reminder_urgency).to eq(:urgent)
      end

      it "returns :final when deadline day" do
        contest.update_column(:judging_deadline_at, Time.current.end_of_day)
        expect(cj.reminder_urgency).to eq(:final)
      end

      it "returns nil when no reminder needed" do
        contest.update_column(:judging_deadline_at, 5.days.from_now)
        expect(cj.reminder_urgency).to be_nil
      end
    end

    describe "#record_reminder_sent!" do
      let(:contest) { create(:contest, :finished, user: organizer) }
      let(:cj) { create(:contest_judge, contest: contest, user: judge_user) }

      it "updates last_reminder_sent_at and increments reminder_count" do
        expect(cj.reminder_count).to eq(0)
        cj.record_reminder_sent!
        cj.reload
        expect(cj.reminder_count).to eq(1)
        expect(cj.last_reminder_sent_at).to be_present
      end
    end
  end
end
