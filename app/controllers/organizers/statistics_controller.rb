# frozen_string_literal: true

module Organizers
  class StatisticsController < BaseController
    before_action :set_contest
    before_action :authorize_contest

    def show
      @service = StatisticsService.new(@contest)
      @summary = @service.summary_stats
      @daily_entries = @service.daily_entries
      @weekly_entries = @service.weekly_entries
      @show_weekly_option = @service.show_weekly_option?
      @spot_rankings = @service.spot_rankings
      @area_distribution = @service.area_distribution
      @daily_votes = @service.daily_votes
      @vote_summary = @service.vote_summary
      @top_voted_entries = @service.top_voted_entries
      @voting_started = @service.voting_started?
    end

    private

    def set_contest
      @contest = Contest.find(params[:contest_id])
    end

    def authorize_contest
      return if @contest.owned_by?(current_user)

      flash[:alert] = "このコンテストにアクセスする権限がありません。"
      redirect_to organizers_contests_path
    end
  end
end
