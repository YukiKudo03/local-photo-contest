# frozen_string_literal: true

class JudgeInvitationService
  attr_reader :contest

  def initialize(contest)
    @contest = contest
  end

  def invite(email:, invited_by:)
    invitation = contest.judge_invitations.create!(
      email: email.downcase.strip,
      invited_by: invited_by,
      invited_at: Time.current
    )

    JudgeInvitationMailer.invite(invitation).deliver_later
    invitation
  end

  def resend(invitation)
    raise "招待は既に処理されています" unless invitation.pending?
    raise "招待の有効期限が切れています" if invitation.expired?

    JudgeInvitationMailer.invite(invitation).deliver_later
    invitation
  end

  def accept(invitation, user)
    invitation.accept!(user)
    invitation
  end

  def decline(invitation)
    invitation.decline!
    invitation
  end
end
