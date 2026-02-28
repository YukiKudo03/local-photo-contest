# frozen_string_literal: true

module Organizers
  class ContestsController < BaseController
    before_action :set_contest, only: [ :show, :edit, :update, :destroy, :publish, :finish, :announce_results ]
    before_action :authorize_contest!, only: [ :show, :edit, :update, :destroy, :publish, :finish, :announce_results ]

    def index
      @contests = current_user.contests
                              .active
                              .includes(thumbnail_attachment: :blob)
                              .recent
      @contests = @contests.by_status(params[:status]) if params[:status].present?
    end

    def show
    end

    def new
      @contest = current_user.contests.build
      @categories = Category.ordered
      @areas = current_user.areas.ordered
      @templates = current_user.contest_templates.recent

      if params[:template_id].present?
        @selected_template = @templates.find_by(id: params[:template_id])
        TemplateService.apply_to_contest(@selected_template, @contest) if @selected_template
      end
    end

    def create
      @contest = current_user.contests.build(contest_params)

      if @contest.save
        redirect_to organizers_contest_path(@contest), notice: t('flash.contests.created')
      else
        @categories = Category.ordered
        @areas = current_user.areas.ordered
        @templates = current_user.contest_templates.recent
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @categories = Category.ordered
      @areas = current_user.areas.ordered
    end

    def update
      if @contest.update(contest_params)
        redirect_to organizers_contest_path(@contest), notice: t('flash.contests.updated')
      else
        @categories = Category.ordered
        @areas = current_user.areas.ordered
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @contest.soft_delete!
      redirect_to organizers_contests_path, notice: t('flash.contests.destroyed')
    rescue RuntimeError => e
      redirect_to organizers_contest_path(@contest), alert: e.message
    end

    def publish
      @contest.publish!
      redirect_to organizers_contest_path(@contest), notice: t('flash.contests.published')
    rescue RuntimeError => e
      redirect_to organizers_contest_path(@contest), alert: e.message
    end

    def finish
      @contest.finish!
      redirect_to organizers_contest_path(@contest), notice: t('flash.contests.finished')
    rescue RuntimeError => e
      redirect_to organizers_contest_path(@contest), alert: e.message
    end

    def announce_results
      @contest.announce_results!
      redirect_to organizers_contest_path(@contest), notice: t('flash.results.announced')
    rescue RuntimeError => e
      redirect_to organizers_contest_path(@contest), alert: e.message
    end

    private

    def set_contest
      @contest = Contest.active.find(params[:id])
    end

    def authorize_contest!
      return if @contest.owned_by?(current_user)

      redirect_to organizers_contests_path, alert: t('flash.contests.not_authorized')
    end

    def contest_params
      params.require(:contest).permit(:title, :description, :theme, :entry_start_at, :entry_end_at, :thumbnail, :category_id, :area_id, :require_spot, :moderation_enabled, :moderation_threshold, :scheduled_publish_at, :scheduled_finish_at, :judging_deadline_at, :auto_archive_days)
    end
  end
end
