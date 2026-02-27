# frozen_string_literal: true

module Admin
  class ContestsController < BaseController
    before_action :set_contest, only: [ :show, :destroy, :force_finish ]

    def index
      @contests = Contest.includes(:user).order(created_at: :desc)
      @contests = @contests.where("title LIKE ?", "%#{params[:q]}%") if params[:q].present?
      @contests = @contests.where(status: params[:status]) if params[:status].present?
      @contests = @contests.page(params[:page]).per(20)
    end

    def show
      @entries = @contest.entries.includes(:user).order(created_at: :desc).limit(20)
      @stats = {
        total_entries: @contest.entries.count,
        total_votes: Vote.joins(:entry).where(entries: { contest_id: @contest.id }).count,
        judges_count: @contest.contest_judges.count,
        pending_moderation: @contest.entries.needs_moderation_review.count
      }
    end

    def destroy
      @contest.destroy
      redirect_to admin_contests_path, notice: t('flash.admin.contests.destroyed')
    end

    def force_finish
      @contest.update!(status: :finished)
      NotificationBroadcaster.contest_status_change(@contest, :finished)
      redirect_to admin_contest_path(@contest), notice: t('flash.admin.contests.force_finished')
    end

    private

    def set_contest
      @contest = Contest.find(params[:id])
    end
  end
end
