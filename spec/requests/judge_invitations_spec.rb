# frozen_string_literal: true

require "rails_helper"

RSpec.describe "JudgeInvitations", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:user) { create(:user, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }
  let(:invitation) { create(:judge_invitation, :pending, contest: contest, invited_by: organizer) }

  describe "GET /judge_invitations/:id" do
    context "with valid pending invitation" do
      it "returns success" do
        get judge_invitation_path(invitation.token)
        expect(response).to have_http_status(:success)
      end

      it "displays invitation details" do
        get judge_invitation_path(invitation.token)
        expect(response.body).to include(contest.title)
        expect(response.body).to include(invitation.email)
      end
    end

    context "with expired invitation" do
      let(:expired_invitation) { create(:judge_invitation, :expired, contest: contest, invited_by: organizer) }

      it "shows invitation details (show allows expired)" do
        get judge_invitation_path(expired_invitation.token)
        expect(response).to have_http_status(:success)
      end
    end

    context "with invalid token" do
      it "returns not found" do
        get judge_invitation_path("invalid-token")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /judge_invitations/:id/accept" do
    context "when authenticated" do
      before { sign_in user }

      context "with valid pending invitation" do
        it "accepts invitation and creates judge assignment" do
          expect {
            post accept_judge_invitation_path(invitation.token)
          }.to change { ContestJudge.count }.by(1)

          expect(response).to redirect_to(my_judge_assignments_path)
          follow_redirect!
          expect(response.body).to include("審査員の招待を承諾しました")
          expect(invitation.reload.accepted?).to be true
        end
      end

      context "when user is already a judge" do
        before { create(:contest_judge, contest: contest, user: user) }

        it "redirects with message" do
          post accept_judge_invitation_path(invitation.token)

          expect(response).to redirect_to(my_judge_assignments_path)
          follow_redirect!
          expect(response.body).to include("既にこのコンテストの審査員として登録されています")
        end
      end

      context "with expired invitation" do
        let(:expired_invitation) { create(:judge_invitation, :expired, contest: contest, invited_by: organizer) }

        it "redirects with error" do
          post accept_judge_invitation_path(expired_invitation.token)

          expect(response).to redirect_to(root_path)
          follow_redirect!
          expect(response.body).to include("有効期限が切れています")
        end
      end

      context "with already accepted invitation" do
        let(:accepted_invitation) { create(:judge_invitation, :accepted, contest: contest, invited_by: organizer, user: create(:user)) }

        it "redirects with error" do
          post accept_judge_invitation_path(accepted_invitation.token)

          expect(response).to redirect_to(root_path)
          follow_redirect!
          expect(response.body).to include("既に承諾されています")
        end
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post accept_judge_invitation_path(invitation.token)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /judge_invitations/:id/decline" do
    context "with valid pending invitation" do
      it "declines invitation" do
        post decline_judge_invitation_path(invitation.token)

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("招待を辞退しました")
        expect(invitation.reload.declined?).to be true
      end
    end

    context "with expired invitation" do
      let(:expired_invitation) { create(:judge_invitation, :expired, contest: contest, invited_by: organizer) }

      it "redirects with error" do
        post decline_judge_invitation_path(expired_invitation.token)

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("有効期限が切れています")
      end
    end

    context "with already declined invitation" do
      let(:declined_invitation) { create(:judge_invitation, :declined, contest: contest, invited_by: organizer) }

      it "redirects with already declined error" do
        post decline_judge_invitation_path(declined_invitation.token)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when decline raises error" do
      it "redirects with error message" do
        allow_any_instance_of(JudgeInvitationService).to receive(:decline).and_raise(StandardError, "decline error")

        post decline_judge_invitation_path(invitation.token)

        expect(response).to redirect_to(judge_invitation_path(invitation.token))
        expect(flash[:alert]).to eq("decline error")
      end
    end
  end

  describe "POST /judge_invitations/:id/accept - error handling" do
    before { sign_in user }

    it "redirects with error when accept raises" do
      allow_any_instance_of(JudgeInvitationService).to receive(:accept).and_raise(StandardError, "accept error")

      post accept_judge_invitation_path(invitation.token)

      expect(response).to redirect_to(judge_invitation_path(invitation.token))
      expect(flash[:alert]).to eq("accept error")
    end
  end
end
