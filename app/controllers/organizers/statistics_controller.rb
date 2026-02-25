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

    def export
      export_service = StatisticsExportService.new(@contest)
      export_type = params[:type] || "daily"

      csv_data, filename = case export_type
      when "summary"
        [ export_service.summary_csv, "summary_#{@contest.id}.csv" ]
      when "entries"
        [ export_service.entries_csv, "entries_#{@contest.id}.csv" ]
      when "spots"
        [ export_service.spots_csv, "spots_#{@contest.id}.csv" ]
      else
        [ export_service.to_csv, "daily_statistics_#{@contest.id}.csv" ]
      end

      send_data csv_data,
                filename: filename,
                type: "text/csv; charset=utf-8"
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
