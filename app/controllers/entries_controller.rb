# frozen_string_literal: true

class EntriesController < ApplicationController
  before_action :authenticate_user!, except: [ :show ]
  before_action :set_contest, only: [ :new, :create ]
  before_action :set_entry, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_entry_visible!, only: [ :show ]
  before_action :authorize_entry!, only: [ :edit, :update, :destroy ]
  before_action :check_editable!, only: [ :edit, :update ]
  before_action :check_deletable!, only: [ :destroy ]

  def new
    @entry = @contest.entries.build
    @areas = Area.ordered
    @spots = @contest.spots.ordered
  end

  def create
    @entry = @contest.entries.build(entry_params)
    @entry.user = current_user

    ActiveRecord::Base.transaction do
      # Handle new spot discovery
      if params.dig(:entry, :discover_new_spot) == "1" && params.dig(:entry, :new_spot_name).present?
        spot = DiscoverySpotService.create_discovered_spot(
          entry: @entry,
          name: params.dig(:entry, :new_spot_name),
          latitude: params.dig(:entry, :new_spot_latitude),
          longitude: params.dig(:entry, :new_spot_longitude),
          comment: params.dig(:entry, :discovery_comment),
          category: params.dig(:entry, :new_spot_category) || :other
        )
        @entry.spot = spot
      end

      if @entry.save
        MilestoneService.new(current_user).check_and_award(:submit_entry, { entry_id: @entry.id })
        PointService.new(current_user).award_for_action("submit_entry", source: @entry)
        redirect_to @entry, notice: discovery_notice
      else
        raise ActiveRecord::Rollback
      end
    end

    unless @entry.persisted?
      @areas = Area.ordered
      @spots = @contest.spots.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @ogp = helpers.set_entry_ogp(@entry)
    @similar_entries = SimilarEntriesService.new(@entry).find
  end

  def edit
    @contest = @entry.contest
    @areas = Area.ordered
    @spots = @contest.spots.ordered
  end

  def update
    @contest = @entry.contest
    if @entry.update(entry_params)
      redirect_to @entry, notice: t('flash.entries.updated')
    else
      @areas = Area.ordered
      @spots = @contest.spots.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @entry.destroy
    redirect_to my_entries_path, notice: t('flash.entries.destroyed')
  end

  private

  def set_contest
    @contest = Contest.published.active.find(params[:contest_id])
  end

  def set_entry
    @entry = Entry.find(params[:id])
  end

  def ensure_entry_visible!
    # Allow owner to see their own entry regardless of status
    return if user_signed_in? && @entry.owned_by?(current_user)

    # For public viewing, entry must be visible and contest must be active
    unless @entry.moderation_approved? || @entry.moderation_pending?
      raise ActiveRecord::RecordNotFound
    end

    unless @entry.contest.published? || @entry.contest.finished?
      raise ActiveRecord::RecordNotFound
    end

    if @entry.contest.deleted_at.present?
      raise ActiveRecord::RecordNotFound
    end
  end

  def authorize_entry!
    return if @entry.owned_by?(current_user)

    redirect_to my_entries_path, alert: t('flash.entries.not_authorized')
  end

  def check_editable!
    return if @entry.editable?

    redirect_to @entry, alert: t('flash.entries.not_editable')
  end

  def check_deletable!
    return if @entry.deletable?

    redirect_to @entry, alert: t('flash.entries.not_deletable')
  end

  def entry_params
    params.require(:entry).permit(:photo, :title, :description, :location, :taken_at, :area_id, :spot_id)
  end

  def discovery_notice
    if params.dig(:entry, :discover_new_spot) == "1" && params.dig(:entry, :new_spot_name).present?
      t('flash.entries.created_with_discovery')
    else
      t('flash.entries.created')
    end
  end
end
