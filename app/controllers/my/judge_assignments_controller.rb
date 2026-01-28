# frozen_string_literal: true

module My
  class JudgeAssignmentsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_contest_judge, only: [ :show ]

    def index
      @assignments = current_user.contest_judges
                                  .includes(contest: :evaluation_criteria)
                                  .joins(:contest)
                                  .merge(Contest.active)
                                  .order("contests.entry_end_at DESC")
    end

    def show
      @contest = @contest_judge.contest
      @entries = @contest.entries.includes(:user, photo_attachment: :blob)
                         .order(created_at: :asc)
      @criteria = @contest.evaluation_criteria.ordered
    end

    private

    def set_contest_judge
      @contest_judge = current_user.contest_judges.find(params[:id])
    end
  end
end
