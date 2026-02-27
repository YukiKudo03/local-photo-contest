# frozen_string_literal: true

module Organizers
  class JudgeInvitationsController < BaseController
    before_action :set_contest
    before_action :authorize_contest!
    before_action :set_invitation, only: [ :destroy, :resend ]

    def index
      @invitations = @contest.judge_invitations.order(created_at: :desc)
      @judges = @contest.contest_judges.includes(:user).order(created_at: :desc)
    end

    def create
      service = JudgeInvitationService.new(@contest)
      @invitation = service.invite(
        email: params[:judge_invitation][:email],
        invited_by: current_user
      )

      redirect_to organizers_contest_judge_invitations_path(@contest),
                  notice: t('flash.judge_invitations.created_with_email', email: @invitation.email)
    rescue ActiveRecord::RecordInvalid => e
      @invitations = @contest.judge_invitations.order(created_at: :desc)
      @judges = @contest.contest_judges.includes(:user).order(created_at: :desc)
      flash.now[:alert] = e.record.errors.full_messages.join(", ")
      render :index, status: :unprocessable_entity
    end

    def destroy
      @invitation.destroy
      redirect_to organizers_contest_judge_invitations_path(@contest),
                  notice: t('flash.judge_invitations.destroyed')
    end

    def resend
      service = JudgeInvitationService.new(@contest)
      service.resend(@invitation)

      redirect_to organizers_contest_judge_invitations_path(@contest),
                  notice: t('flash.judge_invitations.resent')
    rescue => e
      redirect_to organizers_contest_judge_invitations_path(@contest),
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

    def set_invitation
      @invitation = @contest.judge_invitations.find(params[:id])
    end
  end
end
