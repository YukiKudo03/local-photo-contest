# frozen_string_literal: true

module Organizers
  class ContestJudgesController < BaseController
    before_action :set_contest
    before_action :authorize_contest!
    before_action :set_contest_judge, only: [ :destroy ]

    def index
      @judges = @contest.contest_judges.includes(:user).order(created_at: :desc)
      @available_users = User.where.not(id: @contest.judges.pluck(:id))
                             .order(:email)
    end

    def create
      @contest_judge = @contest.contest_judges.build(contest_judge_params)
      @contest_judge.invited_at = Time.current

      if @contest_judge.save
        redirect_to organizers_contest_judges_path(@contest),
                    notice: t('flash.contest_judges.created')
      else
        @judges = @contest.contest_judges.includes(:user).order(created_at: :desc)
        @available_users = User.where.not(id: @contest.judges.pluck(:id)).order(:email)
        flash.now[:alert] = @contest_judge.errors.full_messages.join(", ")
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      @contest_judge.destroy
      redirect_to organizers_contest_judges_path(@contest),
                  notice: t('flash.contest_judges.destroyed')
    end

    private

    def set_contest
      @contest = Contest.active.find(params[:contest_id])
    end

    def authorize_contest!
      return if @contest.owned_by?(current_user)

      redirect_to organizers_contests_path, alert: t('flash.contests.not_authorized')
    end

    def set_contest_judge
      @contest_judge = @contest.contest_judges.find(params[:id])
    end

    def contest_judge_params
      params.require(:contest_judge).permit(:user_id)
    end
  end
end
