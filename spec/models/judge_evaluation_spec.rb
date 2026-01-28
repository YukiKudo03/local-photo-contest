# frozen_string_literal: true

require "rails_helper"

RSpec.describe JudgeEvaluation, type: :model do
  describe "associations" do
    it { should belong_to(:contest_judge) }
    it { should belong_to(:entry) }
    it { should belong_to(:evaluation_criterion) }
  end

  describe "validations" do
    let(:contest) { create(:contest, :published) }
    let(:contest_judge) { create(:contest_judge, contest: contest) }
    let(:entry) { create(:entry, contest: contest) }
    let(:criterion) { create(:evaluation_criterion, contest: contest) }

    subject { build(:judge_evaluation, contest_judge: contest_judge, entry: entry, evaluation_criterion: criterion) }

    it { should validate_presence_of(:score) }
    it { should validate_numericality_of(:score).only_integer.is_greater_than_or_equal_to(1) }

    describe "uniqueness" do
      before do
        create(:judge_evaluation, contest_judge: contest_judge, entry: entry, evaluation_criterion: criterion)
      end

      it "validates uniqueness of entry scoped to contest_judge and criterion" do
        duplicate = build(:judge_evaluation, contest_judge: contest_judge, entry: entry, evaluation_criterion: criterion)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:entry_id]).to include("は既にこの基準で評価済みです")
      end
    end

    describe "score_within_max" do
      let(:criterion_with_max) { create(:evaluation_criterion, contest: contest, max_score: 5, name: "Max5") }

      it "is invalid when score exceeds max_score" do
        evaluation = build(:judge_evaluation, contest_judge: contest_judge, entry: entry,
                                              evaluation_criterion: criterion_with_max, score: 6)
        expect(evaluation).not_to be_valid
        expect(evaluation.errors[:score]).to include("は5以下にしてください")
      end

      it "is valid when score equals max_score" do
        evaluation = build(:judge_evaluation, contest_judge: contest_judge, entry: entry,
                                              evaluation_criterion: criterion_with_max, score: 5)
        expect(evaluation).to be_valid
      end
    end

    describe "cannot_evaluate_own_entry" do
      let(:user) { create(:user, :confirmed) }
      let(:own_entry) { create(:entry, contest: contest, user: user) }
      let(:self_judge) { create(:contest_judge, contest: contest, user: user) }

      it "is invalid when evaluating own entry" do
        evaluation = build(:judge_evaluation, contest_judge: self_judge, entry: own_entry,
                                              evaluation_criterion: criterion)
        expect(evaluation).not_to be_valid
        expect(evaluation.errors[:base]).to include("自分の作品は評価できません")
      end
    end

    describe "entry_belongs_to_contest" do
      let(:other_contest) { create(:contest, :published) }
      let(:other_entry) { create(:entry, contest: other_contest) }

      it "is invalid when entry does not belong to contest" do
        evaluation = build(:judge_evaluation, contest_judge: contest_judge, entry: other_entry,
                                              evaluation_criterion: criterion)
        expect(evaluation).not_to be_valid
        expect(evaluation.errors[:entry]).to include("はこのコンテストの作品ではありません")
      end
    end

    describe "evaluation_editable" do
      it "is invalid when contest results are announced" do
        # Create entry while contest is accepting entries
        entry_for_test = entry
        criterion_for_test = criterion
        # Then finish and announce results
        contest.finish!
        contest.announce_results!

        evaluation = build(:judge_evaluation, contest_judge: contest_judge, entry: entry_for_test,
                                              evaluation_criterion: criterion_for_test)
        expect(evaluation).not_to be_valid
        expect(evaluation.errors[:base]).to include("結果発表後は評価を変更できません")
      end
    end
  end

  describe "delegation" do
    let(:contest) { create(:contest, :published) }
    let(:contest_judge) { create(:contest_judge, contest: contest) }
    let(:entry) { create(:entry, contest: contest) }
    let(:criterion) { create(:evaluation_criterion, contest: contest) }
    let(:evaluation) { create(:judge_evaluation, contest_judge: contest_judge, entry: entry, evaluation_criterion: criterion) }

    it "delegates contest to contest_judge" do
      expect(evaluation.contest).to eq(contest)
    end
  end

  describe "scopes" do
    let(:contest) { create(:contest, :published) }
    let(:contest_judge) { create(:contest_judge, contest: contest) }
    let(:entry1) { create(:entry, contest: contest) }
    let(:entry2) { create(:entry, contest: contest) }
    let(:criterion1) { create(:evaluation_criterion, contest: contest, name: "C1") }
    let(:criterion2) { create(:evaluation_criterion, contest: contest, name: "C2") }
    let!(:eval1) { create(:judge_evaluation, contest_judge: contest_judge, entry: entry1, evaluation_criterion: criterion1) }
    let!(:eval2) { create(:judge_evaluation, contest_judge: contest_judge, entry: entry1, evaluation_criterion: criterion2) }
    let!(:eval3) { create(:judge_evaluation, contest_judge: contest_judge, entry: entry2, evaluation_criterion: criterion1) }

    describe ".for_entry" do
      it "returns evaluations for the specified entry" do
        expect(JudgeEvaluation.for_entry(entry1)).to contain_exactly(eval1, eval2)
      end
    end

    describe ".for_criterion" do
      it "returns evaluations for the specified criterion" do
        expect(JudgeEvaluation.for_criterion(criterion1)).to contain_exactly(eval1, eval3)
      end
    end
  end
end
