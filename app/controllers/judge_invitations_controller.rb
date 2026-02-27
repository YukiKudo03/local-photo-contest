# frozen_string_literal: true

class JudgeInvitationsController < ApplicationController
  before_action :set_invitation
  before_action :check_invitation_valid, except: [ :show ]
  before_action :authenticate_user!, only: [ :accept ]

  def show
    @contest = @invitation.contest
  end

  def accept
    if @invitation.contest.judge?(current_user)
      redirect_to my_judge_assignments_path,
                  notice: t('flash.judge_invitations.already_judge')
      return
    end

    service = JudgeInvitationService.new(@invitation.contest)
    service.accept(@invitation, current_user)

    redirect_to my_judge_assignments_path,
                notice: t('flash.judge_invitations.accepted')
  rescue => e
    redirect_to judge_invitation_path(@invitation.token),
                alert: e.message
  end

  def decline
    service = JudgeInvitationService.new(@invitation.contest)
    service.decline(@invitation)

    redirect_to root_path,
                notice: t('flash.judge_invitations.declined')
  rescue => e
    redirect_to judge_invitation_path(@invitation.token),
                alert: e.message
  end

  private

  def set_invitation
    @invitation = JudgeInvitation.find_by!(token: params[:id])
  end

  def check_invitation_valid
    return if @invitation.pending? && !@invitation.expired?

    if @invitation.expired?
      redirect_to root_path, alert: t('flash.judge_invitations.expired')
    elsif @invitation.accepted?
      redirect_to root_path, alert: t('flash.judge_invitations.already_accepted')
    elsif @invitation.declined?
      redirect_to root_path, alert: t('flash.judge_invitations.already_declined')
    end
  end
end
