# frozen_string_literal: true

class JudgeInvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @contest = invitation.contest
    @accept_url = judge_invitation_url(invitation.token)

    mail(
      to: invitation.email,
      subject: "【#{@contest.title}】審査員への招待"
    )
  end
end
