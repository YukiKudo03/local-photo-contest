# frozen_string_literal: true

class JudgeInvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @contest = invitation.contest
    @accept_url = judge_invitation_url(invitation.token)

    I18n.with_locale(I18n.default_locale) do
      mail(
        to: invitation.email,
        subject: t('mailers.judge_invitation.invite.subject', contest_title: @contest.title)
      )
    end
  end
end
