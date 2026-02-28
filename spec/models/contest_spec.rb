# frozen_string_literal: true

require "rails_helper"

RSpec.describe Contest, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(100) }
    it { is_expected.to validate_length_of(:theme).is_at_most(255) }
    it { is_expected.to validate_presence_of(:status) }

    describe "entry_dates_validity" do
      let(:contest) { build(:contest) }

      context "when entry_end_at is after entry_start_at" do
        before do
          contest.entry_start_at = 1.day.from_now
          contest.entry_end_at = 2.days.from_now
        end

        it "is valid" do
          expect(contest).to be_valid
        end
      end

      context "when entry_end_at is before entry_start_at" do
        before do
          contest.entry_start_at = 2.days.from_now
          contest.entry_end_at = 1.day.from_now
        end

        it "is invalid" do
          expect(contest).not_to be_valid
          expect(contest.errors[:entry_end_at]).to include("は開始日時より後にしてください")
        end
      end

      context "when entry dates are blank" do
        before do
          contest.entry_start_at = nil
          contest.entry_end_at = nil
        end

        it "is valid" do
          expect(contest).to be_valid
        end
      end
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(draft: 0, published: 1, finished: 2) }
  end

  describe "scopes" do
    describe ".active" do
      let!(:active_contest) { create(:contest) }
      let!(:deleted_contest) { create(:contest, :deleted) }

      it "returns only non-deleted contests" do
        expect(Contest.active).to include(active_contest)
        expect(Contest.active).not_to include(deleted_contest)
      end
    end

    describe ".by_status" do
      let!(:draft_contest) { create(:contest, :draft) }
      let!(:published_contest) { create(:contest, :published) }

      it "filters by status" do
        expect(Contest.by_status(:draft)).to include(draft_contest)
        expect(Contest.by_status(:draft)).not_to include(published_contest)
      end
    end

    describe ".recent" do
      let!(:old_contest) { create(:contest, created_at: 2.days.ago) }
      let!(:new_contest) { create(:contest, created_at: 1.day.ago) }

      it "orders by created_at desc" do
        expect(Contest.recent.first).to eq(new_contest)
        expect(Contest.recent.last).to eq(old_contest)
      end
    end
  end

  describe "#publish!" do
    context "when contest is draft" do
      let(:contest) { create(:contest, :draft) }

      it "changes status to published" do
        contest.publish!
        expect(contest.reload).to be_published
      end
    end

    context "when contest is not draft" do
      let(:contest) { create(:contest, :published) }

      it "raises an error" do
        expect { contest.publish! }.to raise_error("Cannot publish: not a draft")
      end
    end

    context "when title is blank" do
      let(:contest) { build(:contest, :draft, title: "") }

      it "raises an error" do
        # Can't save without title due to validation, so we test the check
        contest.title = ""
        expect { contest.publish! }.to raise_error("Cannot publish: title is required")
      end
    end
  end

  describe "#finish!" do
    context "when contest is published" do
      let(:contest) { create(:contest, :published) }

      it "changes status to finished" do
        contest.finish!
        expect(contest.reload).to be_finished
      end
    end

    context "when contest is not published" do
      let(:contest) { create(:contest, :draft) }

      it "raises an error" do
        expect { contest.finish! }.to raise_error("Cannot finish: not published")
      end
    end
  end

  describe "#soft_delete!" do
    context "when contest is draft" do
      let(:contest) { create(:contest, :draft) }

      it "sets deleted_at" do
        expect(contest.deleted_at).to be_nil
        contest.soft_delete!
        expect(contest.reload.deleted_at).not_to be_nil
      end
    end

    context "when contest is finished" do
      let(:contest) { create(:contest, :finished) }

      it "sets deleted_at" do
        expect(contest.deleted_at).to be_nil
        contest.soft_delete!
        expect(contest.reload.deleted_at).not_to be_nil
      end
    end

    context "when contest is published" do
      let(:contest) { create(:contest, :published) }

      it "raises an error" do
        expect { contest.soft_delete! }.to raise_error("Cannot delete: contest is published")
      end
    end
  end

  describe "#accepting_entries?" do
    context "when not published" do
      let(:contest) { create(:contest, :draft) }

      it "returns false" do
        expect(contest.accepting_entries?).to be false
      end
    end

    context "when published without date restrictions" do
      let(:contest) { create(:contest, :published, entry_start_at: nil, entry_end_at: nil) }

      it "returns true" do
        expect(contest.accepting_entries?).to be true
      end
    end

    context "when published and within entry period" do
      let(:contest) { create(:contest, :accepting_entries) }

      it "returns true" do
        expect(contest.accepting_entries?).to be true
      end
    end

    context "when published but entry period has ended" do
      let(:contest) { create(:contest, :entry_ended) }

      it "returns false" do
        expect(contest.accepting_entries?).to be false
      end
    end

    context "when published but entry period has not started" do
      let(:contest) { create(:contest, :published, entry_start_at: 1.day.from_now, entry_end_at: 1.month.from_now) }

      it "returns false" do
        expect(contest.accepting_entries?).to be false
      end
    end
  end

  describe "#owned_by?" do
    let(:user) { create(:user, :organizer, :confirmed) }
    let(:other_user) { create(:user, :organizer, :confirmed) }
    let(:contest) { create(:contest, user: user) }

    it "returns true for the owner" do
      expect(contest.owned_by?(user)).to be true
    end

    it "returns false for other users" do
      expect(contest.owned_by?(other_user)).to be false
    end
  end

  describe "#deleted?" do
    context "when deleted_at is present" do
      let(:contest) { create(:contest, :deleted) }

      it "returns true" do
        expect(contest.deleted?).to be true
      end
    end

    context "when deleted_at is nil" do
      let(:contest) { create(:contest) }

      it "returns false" do
        expect(contest.deleted?).to be false
      end
    end
  end

  describe "#announce_results!" do
    context "when contest is finished" do
      let(:contest) { create(:contest, :finished) }

      it "sets results_announced_at" do
        expect(contest.results_announced_at).to be_nil
        contest.announce_results!
        expect(contest.reload.results_announced_at).not_to be_nil
      end
    end

    context "when contest is not finished" do
      let(:contest) { create(:contest, :published) }

      it "raises an error" do
        expect { contest.announce_results! }.to raise_error("Cannot announce results: contest is not finished")
      end
    end

    context "when results already announced" do
      let(:contest) { create(:contest, :finished, results_announced_at: 1.day.ago) }

      it "raises an error" do
        expect { contest.announce_results! }.to raise_error("Results already announced")
      end
    end
  end

  describe "#results_announced?" do
    context "when results_announced_at is present" do
      let(:contest) { create(:contest, :finished, results_announced_at: 1.day.ago) }

      it "returns true" do
        expect(contest.results_announced?).to be true
      end
    end

    context "when results_announced_at is nil" do
      let(:contest) { create(:contest, :finished) }

      it "returns false" do
        expect(contest.results_announced?).to be false
      end
    end
  end

  describe "#moderation_enabled?" do
    context "when moderation_enabled is true" do
      let(:contest) { create(:contest, moderation_enabled: true) }

      it "returns true" do
        expect(contest.moderation_enabled?).to be true
      end
    end

    context "when moderation_enabled is false" do
      let(:contest) { create(:contest, moderation_enabled: false) }

      it "returns false" do
        expect(contest.moderation_enabled?).to be false
      end
    end
  end

  describe "#effective_moderation_threshold" do
    context "when moderation_threshold is set" do
      let(:contest) { create(:contest, moderation_threshold: 75.0) }

      it "returns the set threshold" do
        expect(contest.effective_moderation_threshold).to eq(75.0)
      end
    end

    context "when moderation_threshold is nil" do
      let(:contest) { create(:contest, moderation_threshold: nil) }

      it "returns the default threshold of 60.0" do
        expect(contest.effective_moderation_threshold).to eq(60.0)
      end
    end
  end

  describe "moderation_threshold validation" do
    it "allows values between 0 and 100" do
      contest = build(:contest, moderation_threshold: 50.0)
      expect(contest).to be_valid
    end

    it "allows nil value" do
      contest = build(:contest, moderation_threshold: nil)
      expect(contest).to be_valid
    end

    it "rejects values less than 0" do
      contest = build(:contest, moderation_threshold: -1)
      expect(contest).not_to be_valid
      expect(contest.errors[:moderation_threshold]).to be_present
    end

    it "rejects values greater than 100" do
      contest = build(:contest, moderation_threshold: 101)
      expect(contest).not_to be_valid
      expect(contest.errors[:moderation_threshold]).to be_present
    end
  end

  describe "#ranked_entries" do
    let(:contest) { create(:contest, :published) }
    let!(:entry1) { create(:entry, contest: contest) }
    let!(:entry2) { create(:entry, contest: contest) }
    let!(:entry3) { create(:entry, contest: contest) }

    before do
      # entry2 has 3 votes, entry1 has 1 vote, entry3 has 0 votes
      3.times { create(:vote, entry: entry2) }
      create(:vote, entry: entry1)
      contest.finish!
    end

    it "returns entries ordered by vote count descending" do
      ranked = contest.ranked_entries.to_a
      expect(ranked.first).to eq(entry2)
      expect(ranked.second).to eq(entry1)
      expect(ranked.third).to eq(entry3)
    end
  end

  describe "#top_entries" do
    let(:contest) { create(:contest, :published) }
    let!(:entries) { create_list(:entry, 5, contest: contest) }

    before do
      entries.each_with_index do |entry, i|
        (5 - i).times { create(:vote, entry: entry) }
      end
      contest.finish!
    end

    it "returns top N entries by default 3" do
      top = contest.top_entries.to_a
      expect(top.length).to eq(3)
    end

    it "accepts a limit parameter" do
      top = contest.top_entries(2).to_a
      expect(top.length).to eq(2)
    end
  end

  describe "#rankings_calculated?" do
    let(:contest) { create(:contest, :published) }

    context "when no rankings exist" do
      it "returns false" do
        expect(contest.rankings_calculated?).to be false
      end
    end

    context "when rankings exist" do
      before do
        create(:entry, contest: contest)
        RankingCalculator.new(contest).calculate
      end

      it "returns true" do
        expect(contest.rankings_calculated?).to be true
      end
    end
  end

  describe "scheduling validations" do
    describe "scheduled_publish_at" do
      context "when contest is draft" do
        it "allows a future scheduled_publish_at" do
          contest = build(:contest, :draft, scheduled_publish_at: 1.day.from_now)
          expect(contest).to be_valid
        end

        it "rejects a past scheduled_publish_at on new record" do
          contest = build(:contest, :draft, scheduled_publish_at: 1.hour.ago)
          expect(contest).not_to be_valid
          expect(contest.errors[:scheduled_publish_at]).to be_present
        end

        it "rejects a past scheduled_publish_at on update" do
          contest = create(:contest, :draft)
          contest.scheduled_publish_at = 1.hour.ago
          expect(contest).not_to be_valid
          expect(contest.errors[:scheduled_publish_at]).to be_present
        end

        it "allows nil scheduled_publish_at" do
          contest = build(:contest, :draft, scheduled_publish_at: nil)
          expect(contest).to be_valid
        end
      end

      context "when contest is already published" do
        it "ignores scheduled_publish_at validation" do
          contest = create(:contest, :published)
          contest.scheduled_publish_at = 1.hour.ago
          expect(contest).to be_valid
        end
      end
    end

    describe "scheduled_finish_at" do
      context "when both scheduled_publish_at and scheduled_finish_at are set" do
        it "rejects scheduled_finish_at before scheduled_publish_at" do
          contest = build(:contest, :draft,
                          scheduled_publish_at: 2.days.from_now,
                          scheduled_finish_at: 1.day.from_now)
          expect(contest).not_to be_valid
          expect(contest.errors[:scheduled_finish_at]).to be_present
        end

        it "allows scheduled_finish_at after scheduled_publish_at" do
          contest = build(:contest, :draft,
                          scheduled_publish_at: 1.day.from_now,
                          scheduled_finish_at: 2.days.from_now)
          expect(contest).to be_valid
        end
      end
    end

    describe "judging_deadline_at" do
      it "allows nil judging_deadline_at" do
        contest = build(:contest, judging_deadline_at: nil)
        expect(contest).to be_valid
      end

      it "rejects judging_deadline_at before entry_end_at" do
        contest = build(:contest,
                        entry_start_at: 1.day.from_now,
                        entry_end_at: 1.month.from_now,
                        judging_deadline_at: 2.weeks.from_now)
        expect(contest).not_to be_valid
        expect(contest.errors[:judging_deadline_at]).to be_present
      end

      it "allows judging_deadline_at after entry_end_at" do
        contest = build(:contest,
                        entry_start_at: 1.day.from_now,
                        entry_end_at: 1.month.from_now,
                        judging_deadline_at: 2.months.from_now)
        expect(contest).to be_valid
      end
    end
  end

  describe "#schedulable_for_publish?" do
    it "returns true for draft contests with scheduled_publish_at in the past" do
      contest = create(:contest, :past_scheduled_publish)
      expect(contest.schedulable_for_publish?).to be true
    end

    it "returns false for draft contests with scheduled_publish_at in the future" do
      contest = create(:contest, :scheduled_for_publish)
      expect(contest.schedulable_for_publish?).to be false
    end

    it "returns false for already-published contests" do
      contest = create(:contest, :published, scheduled_publish_at: 1.hour.ago)
      expect(contest.schedulable_for_publish?).to be false
    end

    it "returns false for draft contests without scheduled_publish_at" do
      contest = create(:contest, :draft)
      expect(contest.schedulable_for_publish?).to be false
    end
  end

  describe "#schedulable_for_finish?" do
    it "returns true for published contests with scheduled_finish_at in the past" do
      contest = create(:contest, :past_scheduled_finish)
      expect(contest.schedulable_for_finish?).to be true
    end

    it "returns false for published contests with scheduled_finish_at in the future" do
      contest = create(:contest, :scheduled_for_finish)
      expect(contest.schedulable_for_finish?).to be false
    end

    it "returns false for already-finished contests" do
      contest = create(:contest, :finished, scheduled_finish_at: 1.hour.ago)
      expect(contest.schedulable_for_finish?).to be false
    end

    it "returns false for published contests without scheduled_finish_at" do
      contest = create(:contest, :published)
      expect(contest.schedulable_for_finish?).to be false
    end
  end

  describe "scopes" do
    describe ".pending_auto_publish" do
      let!(:eligible) { create(:contest, :past_scheduled_publish) }
      let!(:future) { create(:contest, :scheduled_for_publish) }
      let!(:published) { create(:contest, :published) }
      let!(:deleted) { create(:contest, :past_scheduled_publish, :deleted) }

      it "returns only draft contests with past scheduled_publish_at" do
        results = Contest.pending_auto_publish
        expect(results).to include(eligible)
        expect(results).not_to include(future)
        expect(results).not_to include(published)
        expect(results).not_to include(deleted)
      end
    end

    describe ".pending_auto_finish" do
      let!(:eligible) { create(:contest, :past_scheduled_finish) }
      let!(:future) { create(:contest, :scheduled_for_finish) }
      let!(:draft) { create(:contest, :draft) }
      let!(:deleted) { create(:contest, :past_scheduled_finish, :deleted) }

      it "returns only published contests with past scheduled_finish_at" do
        results = Contest.pending_auto_finish
        expect(results).to include(eligible)
        expect(results).not_to include(future)
        expect(results).not_to include(draft)
        expect(results).not_to include(deleted)
      end
    end

    describe ".not_archived" do
      let!(:active_contest) { create(:contest) }
      let!(:archived_contest) { create(:contest, :archived) }

      it "excludes archived contests" do
        expect(Contest.not_archived).to include(active_contest)
        expect(Contest.not_archived).not_to include(archived_contest)
      end
    end
  end

  describe "#rankings_outdated?" do
    let(:organizer) { create(:user, :organizer) }
    let(:contest) { create(:contest, :published, user: organizer, judging_method: :judge_only) }
    let(:participant) { create(:user) }
    let!(:entry) { create(:entry, contest: contest, user: participant) }
    let(:judge) { create(:user) }
    let!(:contest_judge) { create(:contest_judge, contest: contest, user: judge) }
    let!(:criterion) { create(:evaluation_criterion, contest: contest, max_score: 10) }

    context "when no rankings exist" do
      it "returns false" do
        expect(contest.rankings_outdated?).to be false
      end
    end

    context "when rankings exist and no new evaluations" do
      before do
        create(:judge_evaluation, contest_judge: contest_judge, entry: entry, evaluation_criterion: criterion, score: 8)
        RankingCalculator.new(contest).calculate
      end

      it "returns false" do
        expect(contest.rankings_outdated?).to be false
      end
    end

    context "when rankings exist and new evaluation added after calculation" do
      let(:participant2) { create(:user) }
      let!(:entry2) { create(:entry, contest: contest, user: participant2) }

      it "returns true" do
        # Create evaluation and calculate rankings
        create(:judge_evaluation, contest_judge: contest_judge, entry: entry, evaluation_criterion: criterion, score: 8)
        RankingCalculator.new(contest).calculate

        # Backdate the ranking calculation
        contest.contest_rankings.update_all(calculated_at: 1.hour.ago)

        # Add new evaluation (will have current timestamp)
        create(:judge_evaluation, contest_judge: contest_judge, entry: entry2, evaluation_criterion: criterion, score: 9)
        expect(contest.rankings_outdated?).to be true
      end
    end

    context "when rankings exist and evaluation updated after calculation" do
      it "returns true" do
        evaluation = create(:judge_evaluation, contest_judge: contest_judge, entry: entry, evaluation_criterion: criterion, score: 8)
        RankingCalculator.new(contest).calculate

        # Backdate the ranking calculation
        contest.contest_rankings.update_all(calculated_at: 1.hour.ago)

        # Update evaluation (will have current timestamp)
        evaluation.update!(score: 9)
        expect(contest.rankings_outdated?).to be true
      end
    end
  end

  describe "#archive!" do
    let(:organizer) { create(:user, :organizer, :confirmed) }

    context "when contest is finished and results announced" do
      let(:contest) { create(:contest, :finished, user: organizer, results_announced_at: 1.day.ago) }

      it "sets archived_at" do
        contest.archive!
        expect(contest.archived?).to be true
        expect(contest.archived_at).to be_present
      end
    end

    context "when contest is not finished" do
      let(:contest) { create(:contest, :published, user: organizer) }

      it "raises an error" do
        expect { contest.archive! }.to raise_error(RuntimeError)
      end
    end

    context "when results are not announced" do
      let(:contest) { create(:contest, :finished, user: organizer) }

      it "raises an error" do
        expect { contest.archive! }.to raise_error(RuntimeError)
      end
    end

    context "when already archived" do
      let(:contest) { create(:contest, :archived, user: organizer) }

      it "raises an error" do
        expect { contest.archive! }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#unarchive!" do
    let(:organizer) { create(:user, :organizer, :confirmed) }
    let(:contest) { create(:contest, :archived, user: organizer) }

    it "clears archived_at" do
      contest.unarchive!
      expect(contest.archived?).to be false
      expect(contest.archived_at).to be_nil
    end
  end

  describe "#archivable?" do
    let(:organizer) { create(:user, :organizer, :confirmed) }

    it "returns true for finished contest with results announced" do
      contest = create(:contest, :finished, user: organizer, results_announced_at: 1.day.ago)
      expect(contest.archivable?).to be true
    end

    it "returns false for non-finished contest" do
      contest = create(:contest, :published, user: organizer)
      expect(contest.archivable?).to be false
    end

    it "returns false when results not announced" do
      contest = create(:contest, :finished, user: organizer)
      expect(contest.archivable?).to be false
    end

    it "returns false when already archived" do
      contest = create(:contest, :archived, user: organizer)
      expect(contest.archivable?).to be false
    end
  end

  describe "scope: pending_auto_archive" do
    let(:organizer) { create(:user, :organizer, :confirmed) }

    it "returns contests past auto_archive_days since results announcement" do
      contest = create(:contest, :archivable, user: organizer)
      expect(Contest.pending_auto_archive).to include(contest)
    end

    it "excludes contests within auto_archive_days" do
      contest = create(:contest, :finished, user: organizer,
                        results_announced_at: 10.days.ago, auto_archive_days: 90)
      expect(Contest.pending_auto_archive).not_to include(contest)
    end

    it "excludes already archived contests" do
      contest = create(:contest, :archived, user: organizer)
      expect(Contest.pending_auto_archive).not_to include(contest)
    end

    it "excludes contests with nil auto_archive_days" do
      contest = create(:contest, :finished, user: organizer,
                        results_announced_at: 100.days.ago, auto_archive_days: nil)
      expect(Contest.pending_auto_archive).not_to include(contest)
    end
  end
end
