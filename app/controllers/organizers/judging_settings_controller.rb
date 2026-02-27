# frozen_string_literal: true

module Organizers
  class JudgingSettingsController < BaseController
    before_action :set_contest
    before_action :authorize_contest!

    def edit
      @evaluation_criteria = @contest.evaluation_criteria.ordered
    end

    def update
      if @contest.update(judging_settings_params)
        redirect_to edit_organizers_contest_judging_settings_path(@contest),
                    notice: t('flash.judging_settings.updated')
      else
        @evaluation_criteria = @contest.evaluation_criteria.ordered
        flash.now[:alert] = @contest.errors.full_messages.join(", ")
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_contest
      @contest = Contest.active.find(params[:contest_id])
    end

    def authorize_contest!
      return if @contest.owned_by?(current_user)

      redirect_to organizers_contests_path, alert: t('flash.contests.not_authorized')
    end

    def judging_settings_params
      params.require(:contest).permit(
        :judging_method,
        :judge_weight,
        :prize_count,
        :show_detailed_scores
      )
    end
  end
end
