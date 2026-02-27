# frozen_string_literal: true

module Organizers
  class DiscoveryChallengesController < BaseController
    before_action :set_contest
    before_action :authorize_contest!
    before_action :set_challenge, only: [ :show, :edit, :update, :destroy, :activate, :finish ]

    def index
      @challenges = @contest.discovery_challenges.order(created_at: :desc)
    end

    def show
      @entries = @challenge.entries.includes(:user, photo_attachment: :blob).limit(20)
      @discovered_spots = @contest.spots
                                  .where(id: @challenge.entries.joins(:spot).select(:spot_id))
                                  .includes(:discovered_by)
    end

    def new
      @challenge = @contest.discovery_challenges.build
    end

    def create
      @challenge = @contest.discovery_challenges.build(challenge_params)

      if @challenge.save
        redirect_to organizers_contest_discovery_challenges_path(@contest), notice: t('flash.discovery_challenges.created')
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @challenge.update(challenge_params)
        redirect_to organizers_contest_discovery_challenges_path(@contest), notice: t('flash.discovery_challenges.updated')
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @challenge.challenge_active?
        redirect_to organizers_contest_discovery_challenges_path(@contest), alert: t('flash.discovery_challenges.cannot_delete_active')
        return
      end

      @challenge.destroy
      redirect_to organizers_contest_discovery_challenges_path(@contest), notice: t('flash.discovery_challenges.destroyed')
    end

    def activate
      if @challenge.challenge_draft?
        @challenge.update!(status: :active)
        redirect_to organizers_contest_discovery_challenges_path(@contest), notice: t('flash.discovery_challenges.activated')
      else
        redirect_to organizers_contest_discovery_challenges_path(@contest), alert: t('flash.discovery_challenges.cannot_start')
      end
    end

    def finish
      if @challenge.challenge_active?
        @challenge.update!(status: :finished)
        redirect_to organizers_contest_discovery_challenges_path(@contest), notice: t('flash.discovery_challenges.deactivated')
      else
        redirect_to organizers_contest_discovery_challenges_path(@contest), alert: t('flash.discovery_challenges.cannot_finish')
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

    def set_challenge
      @challenge = @contest.discovery_challenges.find(params[:id])
    end

    def challenge_params
      params.require(:discovery_challenge).permit(
        :name,
        :description,
        :theme,
        :starts_at,
        :ends_at
      )
    end
  end
end
