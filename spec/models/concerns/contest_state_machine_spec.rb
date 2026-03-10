# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContestStateMachine, type: :model do
  describe "judging_method_not_changed_after_publish" do
    it "prevents changing judging_method on published contest" do
      contest = create(:contest, :published, judging_method: :vote_only)
      contest.judging_method = :judge_only
      expect(contest).not_to be_valid
      expect(contest.errors[:judging_method]).to be_present
    end

    it "allows changing judging_method on draft contest" do
      contest = create(:contest, :draft, judging_method: :vote_only)
      contest.judging_method = :judge_only
      expect(contest).to be_valid
    end
  end
end
