# frozen_string_literal: true

require "rails_helper"

RSpec.describe JudgeInvitation, type: :model do
  describe ".find_by_token!" do
    let(:invitation) { create(:judge_invitation) }

    it "finds invitation by token" do
      expect(JudgeInvitation.find_by_token!(invitation.token)).to eq(invitation)
    end

    it "raises RecordNotFound for invalid token" do
      expect { JudgeInvitation.find_by_token!("invalid") }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "email_not_already_judge validation" do
    let(:contest) { create(:contest) }
    let(:judge_user) { create(:user, :confirmed) }

    before do
      create(:contest_judge, contest: contest, user: judge_user)
    end

    it "rejects invitation when email is already a judge" do
      invitation = build(:judge_invitation, contest: contest, email: judge_user.email)
      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to be_present
    end
  end
end
