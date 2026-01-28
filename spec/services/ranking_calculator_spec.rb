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
end
