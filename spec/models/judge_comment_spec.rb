# frozen_string_literal: true

require "rails_helper"

RSpec.describe JudgeComment, type: :model do
  describe "associations" do
    it { should belong_to(:contest_judge) }
    it { should belong_to(:entry) }
  end

  describe "validations" do
    let(:contest) { create(:contest, :published) }
    let(:contest_judge) { create(:contest_judge, contest: contest) }
    let(:entry) { create(:entry, contest: contest) }

    subject { build(:judge_comment, contest_judge: contest_judge, entry: entry) }

    it { should validate_presence_of(:comment) }
    it { should validate_length_of(:comment).is_at_most(2000) }

    describe "uniqueness" do
      before do
        create(:judge_comment, contest_judge: contest_judge, entry: entry)
      end

      it "validates uniqueness of entry scoped to contest_judge" do
        duplicate = build(:judge_comment, contest_judge: contest_judge, entry: entry)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:entry_id]).to include("には既にコメント済みです")
      end
    end

    describe "cannot_comment_own_entry" do
      let(:user) { create(:user, :confirmed) }
      let(:own_entry) { create(:entry, contest: contest, user: user) }
      let(:self_judge) { create(:contest_judge, contest: contest, user: user) }

      it "is invalid when commenting on own entry" do
        comment = build(:judge_comment, contest_judge: self_judge, entry: own_entry)
        expect(comment).not_to be_valid
        expect(comment.errors[:base]).to include("自分の作品にはコメントできません")
      end
    end

    describe "comment_editable" do
      it "is invalid when contest results are announced" do
        # Create entry while contest is accepting entries
        entry_for_test = entry
        # Then finish and announce results
        contest.finish!
        contest.announce_results!

        comment = build(:judge_comment, contest_judge: contest_judge, entry: entry_for_test)
        expect(comment).not_to be_valid
        expect(comment.errors[:base]).to include("結果発表後はコメントを変更できません")
      end
    end
  end

  describe "delegation" do
    let(:contest) { create(:contest, :published) }
    let(:user) { create(:user, :confirmed) }
    let(:contest_judge) { create(:contest_judge, contest: contest, user: user) }
    let(:entry) { create(:entry, contest: contest) }
    let(:comment) { create(:judge_comment, contest_judge: contest_judge, entry: entry) }

    it "delegates contest to contest_judge" do
      expect(comment.contest).to eq(contest)
    end

    it "delegates user to contest_judge" do
      expect(comment.user).to eq(user)
    end
  end
end
