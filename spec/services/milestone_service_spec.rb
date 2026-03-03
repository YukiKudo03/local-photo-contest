# frozen_string_literal: true

require "rails_helper"

RSpec.describe MilestoneService do
  let(:user) { create(:user, :confirmed) }
  let(:service) { described_class.new(user) }

  # Helper to create entry in a finished contest (bypassing validation)
  def create_entry_in_finished_contest(user:, contest:)
    entry = build(:entry, user: user, contest: contest)
    entry.save(validate: false)
    entry
  end

  describe "#check_and_award(:vote, ...)" do
    it "awards first_vote milestone on first vote" do
      expect {
        service.check_and_award(:vote, { entry_id: 1 })
      }.to change { user.milestones.where(milestone_type: "first_vote").count }.by(1)
    end

    it "broadcasts achievement notification" do
      allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
      expect(Turbo::StreamsChannel).to receive(:broadcast_append_to).with(
        "user_#{user.id}_notifications",
        hash_including(target: "milestone-notifications")
      ).at_least(:once)
      service.check_and_award(:vote, { entry_id: 1 })
    end

    context "when user has voted 10 times" do
      before do
        contest = create(:contest, :published)
        10.times do
          entry = create(:entry, contest: contest)
          create(:vote, user: user, entry: entry)
        end
      end

      it "awards votes_10 milestone" do
        service.check_and_award(:vote)
        expect(user.achieved_milestone?("votes_10")).to be true
      end
    end

    context "when user has voted 50 times" do
      before do
        contest = create(:contest, :published)
        50.times do
          entry = create(:entry, contest: contest)
          create(:vote, user: user, entry: entry)
        end
      end

      it "awards votes_50 milestone" do
        service.check_and_award(:vote)
        expect(user.achieved_milestone?("votes_50")).to be true
      end
    end
  end

  describe "#check_and_award(:comment, ...)" do
    context "when user has posted 10 comments" do
      before do
        contest = create(:contest, :published)
        entry = create(:entry, contest: contest)
        10.times { create(:comment, user: user, entry: entry) }
      end

      it "awards comments_10 milestone" do
        service.check_and_award(:comment)
        expect(user.achieved_milestone?("comments_10")).to be true
      end
    end

    context "when user has posted 50 comments" do
      before do
        contest = create(:contest, :published)
        entry = create(:entry, contest: contest)
        50.times { create(:comment, user: user, entry: entry) }
      end

      it "awards comments_50 milestone" do
        service.check_and_award(:comment)
        expect(user.achieved_milestone?("comments_50")).to be true
      end
    end
  end

  describe "#check_and_award(:win_prize, ...)" do
    let(:organizer) { create(:user, :organizer, :confirmed) }

    context "when user has 1 prize" do
      before do
        contest = create(:contest, :finished, user: organizer)
        entry = create_entry_in_finished_contest(user: user, contest: contest)
        create(:contest_ranking, :first_place, contest: contest, entry: entry)
      end

      it "awards prize_bronze milestone" do
        service.check_and_award(:win_prize)
        expect(user.achieved_milestone?("prize_bronze")).to be true
      end
    end

    context "when user has 3 prizes" do
      before do
        3.times do
          contest = create(:contest, :finished, user: organizer)
          entry = create_entry_in_finished_contest(user: user, contest: contest)
          create(:contest_ranking, :first_place, contest: contest, entry: entry)
        end
      end

      it "awards prize_silver milestone" do
        service.check_and_award(:win_prize)
        expect(user.achieved_milestone?("prize_silver")).to be true
      end
    end

    context "when user has 5 prizes" do
      before do
        5.times do
          contest = create(:contest, :finished, user: organizer)
          entry = create_entry_in_finished_contest(user: user, contest: contest)
          create(:contest_ranking, :first_place, contest: contest, entry: entry)
        end
      end

      it "awards prize_gold milestone" do
        service.check_and_award(:win_prize)
        expect(user.achieved_milestone?("prize_gold")).to be true
      end
    end
  end

  describe "#check_and_award(:submit_entry, ...)" do
    let(:organizer) { create(:user, :organizer, :confirmed) }

    it "checks consecutive participation milestones" do
      3.times do
        contest = create(:contest, :finished, user: organizer)
        create_entry_in_finished_contest(user: user, contest: contest)
      end

      service.check_and_award(:submit_entry)
      expect(user.achieved_milestone?("consecutive_3_contests")).to be true
    end

    it "does not award if contests are not consecutive" do
      c1 = create(:contest, :finished, user: organizer, created_at: 3.months.ago)
      create_entry_in_finished_contest(user: user, contest: c1)
      _c2 = create(:contest, :finished, user: organizer, created_at: 2.months.ago)
      # user did NOT enter c2
      c3 = create(:contest, :finished, user: organizer, created_at: 1.month.ago)
      create_entry_in_finished_contest(user: user, contest: c3)

      service.check_and_award(:submit_entry)
      expect(user.achieved_milestone?("consecutive_3_contests")).to be false
    end

    it "awards consecutive_5_contests when 5 in a row" do
      5.times do |i|
        contest = create(:contest, :finished, user: organizer, created_at: (5 - i).months.ago)
        create_entry_in_finished_contest(user: user, contest: contest)
      end

      service.check_and_award(:submit_entry)
      expect(user.achieved_milestone?("consecutive_5_contests")).to be true
    end
  end
end
