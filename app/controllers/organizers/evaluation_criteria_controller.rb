# frozen_string_literal: true

module Organizers
  class EvaluationCriteriaController < BaseController
    before_action :set_contest
    before_action :authorize_contest!
    before_action :set_criterion, only: [ :edit, :update, :destroy ]
    before_action :check_editable, only: [ :create, :update, :destroy ]

    def index
      @criteria = @contest.evaluation_criteria.ordered
    end

    def new
      @criterion = @contest.evaluation_criteria.build
    end

    def create
      @criterion = @contest.evaluation_criteria.build(criterion_params)

      if @criterion.save
        redirect_to organizers_contest_evaluation_criteria_path(@contest),
                    notice: t('flash.evaluation_criteria.created')
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @criterion.update(criterion_params)
        redirect_to organizers_contest_evaluation_criteria_path(@contest),
                    notice: t('flash.evaluation_criteria.updated')
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @criterion.destroy
      redirect_to organizers_contest_evaluation_criteria_path(@contest),
                  notice: t('flash.evaluation_criteria.destroyed')
    end

    private

    def set_contest
      @contest = Contest.active.find(params[:contest_id])
    end

    def authorize_contest!
      return if @contest.owned_by?(current_user)

      redirect_to organizers_contests_path, alert: t('flash.contests.not_authorized')
    end

    def set_criterion
      @criterion = @contest.evaluation_criteria.find(params[:id])
    end

    def check_editable
      return unless @contest.results_announced?

      redirect_to organizers_contest_evaluation_criteria_path(@contest),
                  alert: t('flash.evaluation_criteria.not_editable_after_results')
    end

    def criterion_params
      params.require(:evaluation_criterion).permit(:name, :description, :max_score, :position)
    end
  end
end
