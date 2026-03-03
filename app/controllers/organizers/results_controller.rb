# frozen_string_literal: true

module Organizers
  class ResultsController < BaseController
    before_action :set_contest
    before_action :authorize_contest!

    def preview
      service = ResultsAnnouncementService.new(@contest)
      @preview_data = service.preview
      @rankings = @preview_data[:rankings]
      @judge_completion_rate = @preview_data[:judge_completion_rate]
      @can_announce = @preview_data[:can_announce]
      @warnings = @preview_data[:warnings]
    end

    def calculate
      service = ResultsAnnouncementService.new(@contest)
      service.calculate_and_save

      redirect_to preview_organizers_contest_results_path(@contest),
                  notice: t('flash.results.calculated')
    rescue => e
      redirect_to preview_organizers_contest_results_path(@contest),
                  alert: e.message
    end

    def announce
      service = ResultsAnnouncementService.new(@contest)
      service.announce!

      # Award milestones and points for prize winners
      @contest.contest_rankings.each do |ranking|
        entry_owner = ranking.entry.user
        MilestoneService.new(entry_owner).check_and_award(:win_prize, { ranking_id: ranking.id })
        PointService.new(entry_owner).award_for_prize(ranking)
      end

      redirect_to organizers_contest_path(@contest),
                  notice: t('flash.results.announced')
    rescue => e
      redirect_to preview_organizers_contest_results_path(@contest),
                  alert: e.message
    end

    private

    def set_contest
      @contest = Contest.active.find(params[:contest_id])
    end

    def authorize_contest!
      return if @contest.owned_by?(current_user)

      redirect_to organizers_contests_path, alert: t('flash.contests.not_authorized')
    end
  end
end
