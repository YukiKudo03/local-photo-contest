# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResultsAnnouncementService do
  let(:organizer) { create(:user, :organizer, :confirmed) }

  describe "#preview" do
    let(:contest) { create(:contest, :published, user: organizer, judging_method: :vote_only) }
    let!(:entries) { create_list(:entry, 3, contest: contest) }
    let(:service) { described_class.new(contest) }

    before do
      # Create votes: entry[0] = 3 votes, entry[1] = 1 vote, entry[2] = 2 votes
      create_list(:vote, 3, entry: entries[0])
      create(:vote, entry: entries[1])
      create_list(:vote, 2, entry: entries[2])
      contest.finish!
    end

    it "returns preview data with rankings" do
      result = service.preview

      expect(result[:rankings]).to be_an(Array)
      expect(result[:rankings].size).to eq(3)
    end

    it "returns judge completion rate" do
      result = service.preview

      expect(result[:judge_completion_rate]).to be_a(Numeric)
    end

    it "returns can_announce status" do
      result = service.preview

      expect(result[:can_announce]).to be(true)
    end

    it "returns warnings array" do
      result = service.preview

      expect(result[:warnings]).to be_an(Array)
    end
  end

  describe "#calculate_and_save" do
    let(:contest) { create(:contest, :published, user: organizer, judging_method: :vote_only) }
    let!(:entries) { create_list(:entry, 3, contest: contest) }
    let(:service) { described_class.new(contest) }

    before do
      create_list(:vote, 3, entry: entries[0])
      create(:vote, entry: entries[1])
      create_list(:vote, 2, entry: entries[2])
      contest.finish!
    end

    it "saves rankings to the database" do
      expect {
        service.calculate_and_save
      }.to change(ContestRanking, :count).by(3)
    end

    it "ranks entries correctly by vote count" do
      service.calculate_and_save

      rank1 = contest.contest_rankings.find_by(rank: 1)
      rank2 = contest.contest_rankings.find_by(rank: 2)
      rank3 = contest.contest_rankings.find_by(rank: 3)

      expect(rank1.entry).to eq(entries[0]) # 3 votes
      expect(rank2.entry).to eq(entries[2]) # 2 votes
      expect(rank3.entry).to eq(entries[1]) # 1 vote
    end
  end

  describe "#announce!" do
    let(:contest) { create(:contest, :published, user: organizer, judging_method: :vote_only) }
    let!(:entries) { create_list(:entry, 3, contest: contest) }
    let(:service) { described_class.new(contest) }

    before do
      create_list(:vote, 3, entry: entries[0])
      create(:vote, entry: entries[1])
    end

    context "when contest is finished" do
      before { contest.finish! }

      it "calculates rankings and announces results" do
        service.announce!

        expect(contest.reload).to be_results_announced
        expect(contest.contest_rankings.count).to eq(3)
      end
    end

    context "when contest is not finished" do
      it "raises an error" do
        expect {
          service.announce!
        }.to raise_error(RuntimeError, "コンテストが終了していません")
      end
    end

    context "when results are already announced" do
      before do
        contest.finish!
        contest.announce_results!
      end

      it "raises an error" do
        expect {
          service.announce!
        }.to raise_error(RuntimeError, "結果は既に発表されています")
      end
    end
  end

  describe "#can_announce?" do
    let(:contest) { create(:contest, :published, user: organizer, judging_method: :vote_only) }
    let!(:entries) { create_list(:entry, 3, contest: contest) }
    let(:service) { described_class.new(contest) }

    context "when conditions are met" do
      before { contest.finish! }

      it "returns true" do
        expect(service.can_announce?).to be(true)
      end
    end

    context "when contest is not finished" do
      it "returns false" do
        expect(service.can_announce?).to be(false)
      end
    end

    context "when results already announced" do
      before do
        contest.finish!
        contest.announce_results!
      end

      it "returns false" do
        expect(service.can_announce?).to be(false)
      end
    end
  end

  describe "warnings" do
    context "when judge scoring is incomplete" do
      let(:contest) { create(:contest, :published, user: organizer, judging_method: :judge_only) }
      let(:judge) { create(:user, :confirmed) }
      let!(:contest_judge) { create(:contest_judge, contest: contest, user: judge) }
      let!(:criterion) { create(:evaluation_criterion, contest: contest) }
      let!(:entries) { create_list(:entry, 3, contest: contest) }
      let(:service) { described_class.new(contest) }

      before do
        # Only score one entry
        create(:judge_evaluation, contest_judge: contest_judge, entry: entries[0], evaluation_criterion: criterion, score: 5)
        contest.finish!
      end

      it "includes incomplete scoring warning" do
        result = service.preview

        expect(result[:warnings]).to include(match(/採点が.*完了していません/))
      end
    end

    context "when there are no entries" do
      let(:contest) { create(:contest, :published, user: organizer, judging_method: :vote_only) }
      let(:service) { described_class.new(contest) }

      before { contest.finish! }

      it "includes no entries warning" do
        result = service.preview

        expect(result[:warnings]).to include("応募作品がありません")
      end
    end

    context "when judge_only but no judges" do
      let(:contest) { create(:contest, :published, user: organizer, judging_method: :judge_only) }
      let!(:criterion) { create(:evaluation_criterion, contest: contest) }
      let(:service) { described_class.new(contest) }

      before { contest.finish! }

      it "includes no judges warning" do
        result = service.preview

        expect(result[:warnings]).to include("審査員が登録されていません")
      end
    end

    context "when judge_only but no criteria" do
      let(:contest) { create(:contest, :published, user: organizer, judging_method: :judge_only) }
      let(:judge) { create(:user, :confirmed) }
      let!(:contest_judge) { create(:contest_judge, contest: contest, user: judge) }
      let(:service) { described_class.new(contest) }

      before { contest.finish! }

      it "includes no criteria warning" do
        result = service.preview

        expect(result[:warnings]).to include("評価基準が設定されていません")
      end
    end

    context "when rankings are outdated" do
      let(:contest) { create(:contest, :published, user: organizer, judging_method: :vote_only) }
      let!(:entries) { create_list(:entry, 2, contest: contest) }
      let(:service) { described_class.new(contest) }

      before do
        contest.finish!
        allow(contest).to receive(:rankings_outdated?).and_return(true)
      end

      it "includes rankings outdated warning" do
        result = service.preview
        expect(result[:warnings]).to include(I18n.t("services.results.rankings_outdated"))
      end
    end
  end
end
