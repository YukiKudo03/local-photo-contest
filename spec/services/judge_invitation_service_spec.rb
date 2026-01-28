# frozen_string_literal: true

require "rails_helper"

RSpec.describe JudgeInvitationService do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }
  let(:service) { described_class.new(contest) }

  describe "#invite" do
    let(:email) { "newjudge@example.com" }

    it "creates a judge invitation" do
      expect {
        service.invite(email: email, invited_by: organizer)
      }.to change(JudgeInvitation, :count).by(1)
    end

    it "normalizes the email address" do
      invitation = service.invite(email: "  Judge@Example.COM  ", invited_by: organizer)

      expect(invitation.email).to eq("judge@example.com")
    end

    it "sends an invitation email" do
      expect {
        service.invite(email: email, invited_by: organizer)
      }.to have_enqueued_mail(JudgeInvitationMailer, :invite)
    end

    it "returns the created invitation" do
      invitation = service.invite(email: email, invited_by: organizer)

      expect(invitation).to be_a(JudgeInvitation)
      expect(invitation).to be_persisted
      expect(invitation.email).to eq(email)
      expect(invitation.contest).to eq(contest)
      expect(invitation.invited_by).to eq(organizer)
    end

    context "when email is already invited" do
      before { create(:judge_invitation, contest: contest, email: email) }

      it "raises an error" do
        expect {
          service.invite(email: email, invited_by: organizer)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "#resend" do
    let(:invitation) { create(:judge_invitation, contest: contest) }

    it "sends the invitation email again" do
      expect {
        service.resend(invitation)
      }.to have_enqueued_mail(JudgeInvitationMailer, :invite)
    end

    context "when invitation is already accepted" do
      let(:invitation) { create(:judge_invitation, :accepted, contest: contest) }

      it "raises an error" do
        expect {
          service.resend(invitation)
        }.to raise_error(RuntimeError, "招待は既に処理されています")
      end
    end

    context "when invitation is already declined" do
      let(:invitation) { create(:judge_invitation, :declined, contest: contest) }

      it "raises an error" do
        expect {
          service.resend(invitation)
        }.to raise_error(RuntimeError, "招待は既に処理されています")
      end
    end

    context "when invitation is expired" do
      let(:invitation) { create(:judge_invitation, :expired, contest: contest) }

      it "raises an error" do
        expect {
          service.resend(invitation)
        }.to raise_error(RuntimeError, "招待の有効期限が切れています")
      end
    end
  end

  describe "#accept" do
    let(:invitation) { create(:judge_invitation, contest: contest) }
    let(:user) { create(:user, :confirmed) }

    it "accepts the invitation" do
      service.accept(invitation, user)

      expect(invitation.reload).to be_accepted
      expect(invitation.user).to eq(user)
    end

    it "creates a contest judge" do
      expect {
        service.accept(invitation, user)
      }.to change(ContestJudge, :count).by(1)

      contest_judge = contest.contest_judges.last
      expect(contest_judge.user).to eq(user)
    end

    context "when invitation is already processed" do
      let(:invitation) { create(:judge_invitation, :accepted, contest: contest) }

      it "raises an error" do
        expect {
          service.accept(invitation, user)
        }.to raise_error(RuntimeError, "招待が既に処理されています")
      end
    end

    context "when invitation is expired" do
      let(:invitation) { create(:judge_invitation, :expired, contest: contest) }

      it "raises an error" do
        expect {
          service.accept(invitation, user)
        }.to raise_error(RuntimeError, "招待の有効期限が切れています")
      end
    end
  end

  describe "#decline" do
    let(:invitation) { create(:judge_invitation, contest: contest) }

    it "declines the invitation" do
      service.decline(invitation)

      expect(invitation.reload).to be_declined
    end

    context "when invitation is already processed" do
      let(:invitation) { create(:judge_invitation, :accepted, contest: contest) }

      it "raises an error" do
        expect {
          service.decline(invitation)
        }.to raise_error(RuntimeError, "招待が既に処理されています")
      end
    end
  end
end
