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
                  notice: "ランキングを計算しました。"
    rescue => e
      redirect_to preview_organizers_contest_results_path(@contest),
                  alert: e.message
    end

    def announce
      service = ResultsAnnouncementService.new(@contest)
      service.announce!

      redirect_to organizers_contest_path(@contest),
                  notice: "結果を発表しました。"
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

      redirect_to organizers_contests_path, alert: "この操作を行う権限がありません。"
    end
  end
end
