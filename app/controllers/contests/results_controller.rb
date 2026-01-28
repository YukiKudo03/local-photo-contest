# frozen_string_literal: true

module Contests
  class ResultsController < ApplicationController
    before_action :set_contest

    def show
      unless @contest.results_announced?
        redirect_to contest_path(@contest), alert: "結果はまだ発表されていません。"
        return
      end

      @rankings = @contest.calculated_rankings.includes(entry: [ :user, { photo_attachment: :blob } ])
      @prize_rankings = @rankings.where("rank <= ?", @contest.effective_prize_count)
      @all_rankings = @rankings

      # For logged in participants, find their ranking
      if user_signed_in?
        @my_ranking = @rankings.joins(:entry).find_by(entries: { user_id: current_user.id })
      end
    end

    private

    def set_contest
      @contest = Contest.published.or(Contest.finished).find(params[:contest_id])
    end
  end
end
