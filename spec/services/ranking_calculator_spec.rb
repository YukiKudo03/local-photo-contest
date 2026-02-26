# frozen_string_literal: true

require "rails_helper"

RSpec.describe RankingCalculator do
  let(:organizer) { create(:user, :organizer) }
  let(:contest) { create(:contest, :published, user: organizer, judging_method: :judge_only) }
  let(:participants) { create_list(:user, 3) }
  let!(:entries) do
    participants.map { |p| create(:entry, contest: contest, user: p) }
  end

  describe "#calculate" do
    context "with judge_only method" do
      let(:judge) { create(:user) }
      let!(:contest_judge) { create(:contest_judge, contest: contest, user: judge) }
      let!(:criterion) { create(:evaluation_criterion, contest: contest, max_score: 10) }

      before do
        # Entry 0: score 8
        create(:judge_evaluation, contest_judge: contest_judge, entry: entries[0], evaluation_criterion: criterion, score: 8)
        # Entry 1: score 5
        create(:judge_evaluation, contest_judge: contest_judge, entry: entries[1], evaluation_criterion: criterion, score: 5)
        # Entry 2: score 10
        create(:judge_evaluation, contest_judge: contest_judge, entry: entries[2], evaluation_criterion: criterion, score: 10)
      end

      it "calculates rankings based on judge scores" do
        calculator = described_class.new(contest)
        rankings = calculator.calculate

        expect(rankings.size).to eq(3)
        expect(rankings[0][:entry]).to eq(entries[2]) # score 10 -> rank 1
        expect(rankings[0][:rank]).to eq(1)
        expect(rankings[1][:entry]).to eq(entries[0]) # score 8 -> rank 2
        expect(rankings[1][:rank]).to eq(2)
        expect(rankings[2][:entry]).to eq(entries[1]) # score 5 -> rank 3
        expect(rankings[2][:rank]).to eq(3)
      end

      it "saves rankings to the database" do
        calculator = described_class.new(contest)
        calculator.calculate

        expect(contest.contest_rankings.count).to eq(3)
        expect(contest.contest_rankings.find_by(rank: 1).entry).to eq(entries[2])
      end
    end

    context "with vote_only method" do
      let(:contest) { create(:contest, :published, user: organizer, judging_method: :vote_only) }
      let(:voters) { create_list(:user, 10) }

      before do
        # Entry 0: 3 votes
        voters[0..2].each { |v| create(:vote, entry: entries[0], user: v) }
        # Entry 1: 5 votes
        voters[0..4].each { |v| create(:vote, entry: entries[1], user: v) }
        # Entry 2: 2 votes
        voters[0..1].each { |v| create(:vote, entry: entries[2], user: v) }
      end

      it "calculates rankings based on vote count" do
        calculator = described_class.new(contest)
        rankings = calculator.calculate

        expect(rankings[0][:entry]).to eq(entries[1]) # 5 votes -> rank 1
        expect(rankings[0][:vote_count]).to eq(5)
        expect(rankings[1][:entry]).to eq(entries[0]) # 3 votes -> rank 2
        expect(rankings[2][:entry]).to eq(entries[2]) # 2 votes -> rank 3
      end
    end

    context "with hybrid method" do
      let(:contest) { create(:contest, :published, user: organizer, judging_method: :hybrid, judge_weight: 70) }
      let(:judge) { create(:user) }
      let!(:contest_judge) { create(:contest_judge, contest: contest, user: judge) }
      let!(:criterion) { create(:evaluation_criterion, contest: contest, max_score: 10) }
      let(:voters) { create_list(:user, 10) }

      before do
        # Entry 0: score 10, 2 votes -> high judge, low votes
        create(:judge_evaluation, contest_judge: contest_judge, entry: entries[0], evaluation_criterion: criterion, score: 10)
        voters[0..1].each { |v| create(:vote, entry: entries[0], user: v) }

        # Entry 1: score 5, 5 votes -> low judge, high votes
        create(:judge_evaluation, contest_judge: contest_judge, entry: entries[1], evaluation_criterion: criterion, score: 5)
        voters[0..4].each { |v| create(:vote, entry: entries[1], user: v) }

        # Entry 2: score 8, 3 votes -> medium both
        create(:judge_evaluation, contest_judge: contest_judge, entry: entries[2], evaluation_criterion: criterion, score: 8)
        voters[0..2].each { |v| create(:vote, entry: entries[2], user: v) }
      end

      it "calculates rankings combining judge scores and votes" do
        calculator = described_class.new(contest)
        rankings = calculator.calculate

        # With 70% judge weight:
        # Entry 0: (100 * 0.7) + (40 * 0.3) = 70 + 12 = 82
        # Entry 1: (50 * 0.7) + (100 * 0.3) = 35 + 30 = 65
        # Entry 2: (80 * 0.7) + (60 * 0.3) = 56 + 18 = 74

        expect(rankings[0][:entry]).to eq(entries[0]) # 82 -> rank 1
        expect(rankings[1][:entry]).to eq(entries[2]) # 74 -> rank 2
        expect(rankings[2][:entry]).to eq(entries[1]) # 65 -> rank 3
      end
    end

    context "with tiebreaker" do
      let(:contest) { create(:contest, :published, user: organizer, judging_method: :vote_only) }
      let(:voters) { create_list(:user, 5) }

      before do
        # All entries have same vote count
        voters[0..2].each do |v|
          entries.each { |e| create(:vote, entry: e, user: v) }
        end
      end

      it "breaks ties by created_at" do
        calculator = described_class.new(contest)
        rankings = calculator.calculate

        # Same votes, so order by created_at (earliest first)
        expect(rankings[0][:entry]).to eq(entries[0])
        expect(rankings[1][:entry]).to eq(entries[1])
        expect(rankings[2][:entry]).to eq(entries[2])
      end
    end
  end

  describe "#preview" do
    it "returns rankings without saving" do
      calculator = described_class.new(contest)
      rankings = calculator.preview

      expect(rankings.size).to eq(3)
      expect(contest.contest_rankings.count).to eq(0)
    end
  end

  describe "edge cases" do
    context "when there are no judges" do
      let(:contest) { create(:contest, :published, user: organizer, judging_method: :judge_only) }

      it "handles entries without any judge evaluations" do
        calculator = described_class.new(contest)
        rankings = calculator.calculate

        # All entries should have 0 judge score
        expect(rankings.size).to eq(3)
        rankings.each do |ranking|
          expect(ranking[:judge_score]).to eq(0)
          expect(ranking[:total_score]).to eq(0)
        end
      end

      it "assigns same rank when scores are identical (standard competition ranking)" do
        calculator = described_class.new(contest)
        rankings = calculator.calculate

        # With all scores at 0, all entries get rank 1 (standard competition ranking)
        # created_at determines ordering but not rank
        expect(rankings[0][:entry]).to eq(entries[0])
        expect(rankings[0][:rank]).to eq(1)
        expect(rankings[1][:entry]).to eq(entries[1])
        expect(rankings[1][:rank]).to eq(1)  # Same rank as first entry
        expect(rankings[2][:entry]).to eq(entries[2])
        expect(rankings[2][:rank]).to eq(1)  # Same rank as first entry
      end
    end

    context "when there are no entries" do
      let(:contest_no_entries) { create(:contest, :published, user: organizer, judging_method: :judge_only) }

      it "returns empty rankings" do
        calculator = described_class.new(contest_no_entries)
        rankings = calculator.calculate

        expect(rankings).to be_empty
        expect(contest_no_entries.contest_rankings.count).to eq(0)
      end
    end

    context "when all entries have exact same score" do
      let(:contest) { create(:contest, :published, user: organizer, judging_method: :judge_only) }
      let(:judge) { create(:user) }
      let!(:contest_judge) { create(:contest_judge, contest: contest, user: judge) }
      let!(:criterion) { create(:evaluation_criterion, contest: contest, max_score: 10) }

      before do
        entries.each do |entry|
          create(:judge_evaluation, contest_judge: contest_judge, entry: entry, evaluation_criterion: criterion, score: 7)
        end
      end

      it "assigns same rank for identical scores (standard competition ranking)" do
        calculator = described_class.new(contest)
        rankings = calculator.calculate

        # All have same score (7 out of 10 = 70 normalized), all get rank 1
        # created_at determines ordering but not rank
        expect(rankings[0][:rank]).to eq(1)
        expect(rankings[1][:rank]).to eq(1)
        expect(rankings[2][:rank]).to eq(1)
        # All entries should have same normalized score
        expect(rankings.map { |r| r[:judge_score] }.uniq.size).to eq(1)
      end

      it "orders by created_at for same scores" do
        calculator = described_class.new(contest)
        rankings = calculator.calculate

        expect(rankings[0][:entry]).to eq(entries[0])
        expect(rankings[1][:entry]).to eq(entries[1])
        expect(rankings[2][:entry]).to eq(entries[2])
      end
    end

    context "when judge evaluation is partial (not all judges evaluated)" do
      let(:contest) { create(:contest, :published, user: organizer, judging_method: :judge_only) }
      let(:judge1) { create(:user) }
      let(:judge2) { create(:user) }
      let!(:contest_judge1) { create(:contest_judge, contest: contest, user: judge1) }
      let!(:contest_judge2) { create(:contest_judge, contest: contest, user: judge2) }
      let!(:criterion) { create(:evaluation_criterion, contest: contest, max_score: 10) }

      before do
        # Judge 1 evaluates all entries
        create(:judge_evaluation, contest_judge: contest_judge1, entry: entries[0], evaluation_criterion: criterion, score: 8)
        create(:judge_evaluation, contest_judge: contest_judge1, entry: entries[1], evaluation_criterion: criterion, score: 6)
        create(:judge_evaluation, contest_judge: contest_judge1, entry: entries[2], evaluation_criterion: criterion, score: 10)

        # Judge 2 only evaluates first entry (partial)
        create(:judge_evaluation, contest_judge: contest_judge2, entry: entries[0], evaluation_criterion: criterion, score: 9)
      end

      it "calculates average from available evaluations" do
        calculator = described_class.new(contest)
        rankings = calculator.calculate

        # Entry 0: (8 + 9) / 2 = 8.5
        # Entry 1: 6 / 1 = 6
        # Entry 2: 10 / 1 = 10
        expect(rankings[0][:entry]).to eq(entries[2]) # score 10
        expect(rankings[1][:entry]).to eq(entries[0]) # score 8.5
        expect(rankings[2][:entry]).to eq(entries[1]) # score 6
      end
    end

    context "when judge leaves mid-contest (evaluations removed)" do
      let(:contest) { create(:contest, :published, user: organizer, judging_method: :judge_only) }
      let(:judge1) { create(:user) }
      let(:judge2) { create(:user) }
      let!(:contest_judge1) { create(:contest_judge, contest: contest, user: judge1) }
      let!(:contest_judge2) { create(:contest_judge, contest: contest, user: judge2) }
      let!(:criterion) { create(:evaluation_criterion, contest: contest, max_score: 10) }

      before do
        # Both judges evaluate all entries
        entries.each_with_index do |entry, i|
          create(:judge_evaluation, contest_judge: contest_judge1, entry: entry, evaluation_criterion: criterion, score: 5 + i)
          create(:judge_evaluation, contest_judge: contest_judge2, entry: entry, evaluation_criterion: criterion, score: 7 + i)
        end

        # Judge 2 leaves - remove their evaluations
        JudgeEvaluation.where(contest_judge: contest_judge2).destroy_all
      end

      it "recalculates rankings with remaining judge evaluations" do
        calculator = described_class.new(contest)
        rankings = calculator.calculate

        # Only judge1's scores remain: 5, 6, 7
        expect(rankings[0][:entry]).to eq(entries[2]) # score 7
        expect(rankings[1][:entry]).to eq(entries[1]) # score 6
        expect(rankings[2][:entry]).to eq(entries[0]) # score 5
      end
    end

    context "with mixed vote and judge in hybrid mode" do
      let(:contest) { create(:contest, :published, user: organizer, judging_method: :hybrid, judge_weight: 50) }
      let(:voters) { create_list(:user, 5) }

      context "when there are only votes (no judge scores)" do
        before do
          voters[0..2].each { |v| create(:vote, entry: entries[0], user: v) }
          voters[0..1].each { |v| create(:vote, entry: entries[1], user: v) }
          voters[0..0].each { |v| create(:vote, entry: entries[2], user: v) }
        end

        it "calculates ranking based only on votes" do
          calculator = described_class.new(contest)
          rankings = calculator.calculate

          # Hybrid with 50% judge (0) + 50% vote
          # Entry 0: 0 + 50 * (3/3) = 50
          # Entry 1: 0 + 50 * (2/3) = 33.33
          # Entry 2: 0 + 50 * (1/3) = 16.67
          expect(rankings[0][:entry]).to eq(entries[0])
          expect(rankings[1][:entry]).to eq(entries[1])
          expect(rankings[2][:entry]).to eq(entries[2])
        end
      end

      context "when there are only judge scores (no votes)" do
        let(:judge) { create(:user) }
        let!(:contest_judge) { create(:contest_judge, contest: contest, user: judge) }
        let!(:criterion) { create(:evaluation_criterion, contest: contest, max_score: 10) }

        before do
          create(:judge_evaluation, contest_judge: contest_judge, entry: entries[0], evaluation_criterion: criterion, score: 5)
          create(:judge_evaluation, contest_judge: contest_judge, entry: entries[1], evaluation_criterion: criterion, score: 10)
          create(:judge_evaluation, contest_judge: contest_judge, entry: entries[2], evaluation_criterion: criterion, score: 7)
        end

        it "calculates ranking based only on judge scores" do
          calculator = described_class.new(contest)
          rankings = calculator.calculate

          # Hybrid with 50% judge + 50% vote (0)
          expect(rankings[0][:entry]).to eq(entries[1]) # score 10
          expect(rankings[1][:entry]).to eq(entries[2]) # score 7
          expect(rankings[2][:entry]).to eq(entries[0]) # score 5
        end
      end
    end

    context "when entries have identical scores (same rank assignment)" do
      let(:tie_contest) { create(:contest, :published, user: organizer, judging_method: :judge_only) }
      let(:judge) { create(:user) }
      let!(:contest_judge) { create(:contest_judge, contest: tie_contest, user: judge) }
      let!(:criterion) { create(:evaluation_criterion, contest: tie_contest, max_score: 10) }
      let(:tie_participants) { create_list(:user, 5) }
      let!(:five_entries) do
        tie_participants.map { |p| create(:entry, contest: tie_contest, user: p) }
      end

      before do
        # Entry 0: score 10 -> rank 1
        # Entry 1: score 10 -> rank 1 (same as entry 0)
        # Entry 2: score 8 -> rank 3 (skips rank 2)
        # Entry 3: score 8 -> rank 3 (same as entry 2)
        # Entry 4: score 5 -> rank 5 (skips rank 4)
        create(:judge_evaluation, contest_judge: contest_judge, entry: five_entries[0], evaluation_criterion: criterion, score: 10)
        create(:judge_evaluation, contest_judge: contest_judge, entry: five_entries[1], evaluation_criterion: criterion, score: 10)
        create(:judge_evaluation, contest_judge: contest_judge, entry: five_entries[2], evaluation_criterion: criterion, score: 8)
        create(:judge_evaluation, contest_judge: contest_judge, entry: five_entries[3], evaluation_criterion: criterion, score: 8)
        create(:judge_evaluation, contest_judge: contest_judge, entry: five_entries[4], evaluation_criterion: criterion, score: 5)
      end

      it "assigns same rank to entries with identical scores" do
        calculator = described_class.new(tie_contest)
        rankings = calculator.calculate

        # Entries with score 10 should both have rank 1
        score_10_rankings = rankings.select { |r| r[:judge_score] == 100.0 }
        expect(score_10_rankings.map { |r| r[:rank] }.uniq).to eq([1])
        expect(score_10_rankings.size).to eq(2)
      end

      it "skips ranks appropriately after ties" do
        calculator = described_class.new(tie_contest)
        rankings = calculator.calculate

        ranks = rankings.map { |r| r[:rank] }
        # Two rank 1s, two rank 3s, one rank 5
        expect(ranks.sort).to eq([1, 1, 3, 3, 5])
      end

      it "saves correct ranks to database" do
        calculator = described_class.new(tie_contest)
        calculator.calculate

        saved_rankings = tie_contest.contest_rankings.reload
        ranks = saved_rankings.map(&:rank).sort
        expect(ranks).to eq([1, 1, 3, 3, 5])
      end
    end

    context "when all entries have identical scores and votes" do
      let(:tie_contest) { create(:contest, :published, user: organizer, judging_method: :vote_only) }
      let(:tie_participants) { create_list(:user, 3) }
      let!(:tie_entries) do
        tie_participants.map { |p| create(:entry, contest: tie_contest, user: p) }
      end
      let(:voters) { create_list(:user, 3) }

      before do
        # All entries get exactly 2 votes each
        voters[0..1].each do |voter|
          tie_entries.each { |entry| create(:vote, entry: entry, user: voter) }
        end
      end

      it "assigns rank 1 to all entries with identical scores" do
        calculator = described_class.new(tie_contest)
        rankings = calculator.calculate

        # All should have rank 1
        expect(rankings.map { |r| r[:rank] }.uniq).to eq([1])
      end
    end
  end
end
