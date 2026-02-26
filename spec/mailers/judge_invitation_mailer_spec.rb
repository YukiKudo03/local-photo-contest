# frozen_string_literal: true

require "rails_helper"

RSpec.describe JudgeInvitationMailer, type: :mailer do
  describe "#invite" do
    let(:contest) { create(:contest, :published, title: "写真コンテスト2026") }
    let(:invitation) { create(:judge_invitation, contest: contest, email: "judge@example.com") }
    let(:mail) { described_class.invite(invitation) }

    it "renders the headers" do
      expect(mail.subject).to eq("【写真コンテスト2026】審査員への招待")
      expect(mail.to).to eq([ "judge@example.com" ])
    end

    it "renders the body with invitation token link" do
      # Check either HTML or text part for the token
      body_text = mail.body.parts.map(&:decoded).join
      expect(body_text).to include(invitation.token)
    end

    it "includes contest title in body" do
      body_text = mail.body.parts.map(&:decoded).join
      expect(body_text).to include("写真コンテスト2026")
    end
  end
end
