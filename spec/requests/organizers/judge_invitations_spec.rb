# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::JudgeInvitations", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:other_organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }

  describe "GET /organizers/contests/:contest_id/judge_invitations" do
    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "returns success" do
        get organizers_contest_judge_invitations_path(contest)
        expect(response).to have_http_status(:success)
      end

      context "with existing invitations" do
        let!(:invitation) { create(:judge_invitation, contest: contest, invited_by: organizer) }

        it "displays invitations" do
          get organizers_contest_judge_invitations_path(contest)
          expect(response.body).to include(invitation.email)
        end
      end
    end

    context "when authenticated as different organizer" do
      before { sign_in other_organizer }

      it "redirects with unauthorized message" do
        get organizers_contest_judge_invitations_path(contest)
        expect(response).to redirect_to(organizers_contests_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get organizers_contest_judge_invitations_path(contest)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /organizers/contests/:contest_id/judge_invitations" do
    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "creates invitation and enqueues email" do
        expect {
          post organizers_contest_judge_invitations_path(contest), params: {
            judge_invitation: { email: "judge@example.com" }
          }
        }.to change { JudgeInvitation.count }.by(1)

        expect(response).to redirect_to(organizers_contest_judge_invitations_path(contest))
        follow_redirect!
        expect(response.body).to include("judge@example.com")
        expect(response.body).to include("招待メールを送信しました")
      end

      context "with invalid email" do
        it "renders index with error" do
          post organizers_contest_judge_invitations_path(contest), params: {
            judge_invitation: { email: "" }
          }

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "with duplicate email" do
        let!(:existing) { create(:judge_invitation, contest: contest, email: "judge@example.com", invited_by: organizer) }

        it "renders index with error" do
          post organizers_contest_judge_invitations_path(contest), params: {
            judge_invitation: { email: "judge@example.com" }
          }

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when authenticated as different organizer" do
      before { sign_in other_organizer }

      it "redirects with unauthorized message" do
        post organizers_contest_judge_invitations_path(contest), params: {
          judge_invitation: { email: "judge@example.com" }
        }

        expect(response).to redirect_to(organizers_contests_path)
        expect(JudgeInvitation.count).to eq(0)
      end
    end
  end

  describe "DELETE /organizers/contests/:contest_id/judge_invitations/:id" do
    let!(:invitation) { create(:judge_invitation, contest: contest, invited_by: organizer) }

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "destroys the invitation" do
        expect {
          delete organizers_contest_judge_invitation_path(contest, invitation)
        }.to change { JudgeInvitation.count }.by(-1)

        expect(response).to redirect_to(organizers_contest_judge_invitations_path(contest))
        follow_redirect!
        expect(response.body).to include("招待を取り消しました")
      end
    end

    context "when authenticated as different organizer" do
      before { sign_in other_organizer }

      it "redirects with unauthorized message" do
        delete organizers_contest_judge_invitation_path(contest, invitation)
        expect(response).to redirect_to(organizers_contests_path)
        expect(invitation.reload).to be_persisted
      end
    end
  end

  describe "POST /organizers/contests/:contest_id/judge_invitations/:id/resend" do
    let!(:invitation) { create(:judge_invitation, contest: contest, invited_by: organizer) }

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "resends the invitation email" do
        post resend_organizers_contest_judge_invitation_path(contest, invitation)

        expect(response).to redirect_to(organizers_contest_judge_invitations_path(contest))
        follow_redirect!
        expect(response.body).to include("招待を再送信しました")
      end
    end

    context "when authenticated as different organizer" do
      before { sign_in other_organizer }

      it "redirects with unauthorized message" do
        post resend_organizers_contest_judge_invitation_path(contest, invitation)
        expect(response).to redirect_to(organizers_contests_path)
      end
    end
  end
end
