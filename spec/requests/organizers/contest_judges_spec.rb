# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::ContestJudges", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:other_organizer) { create(:user, :organizer, :confirmed) }
  let(:judge_user) { create(:user, :confirmed) }
  let(:terms) { create(:terms_of_service, :current) }
  let(:contest) { create(:contest, :published, user: organizer) }

  before do
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    create(:terms_acceptance, user: other_organizer, terms_of_service: terms)
  end

  describe "GET /organizers/contests/:contest_id/judges" do
    context "when not authenticated" do
      it "redirects to login" do
        get organizers_contest_judges_path(contest)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "returns success" do
        get organizers_contest_judges_path(contest)
        expect(response).to have_http_status(:success)
      end

      it "lists all judges" do
        judge = create(:contest_judge, contest: contest, user: judge_user)

        get organizers_contest_judges_path(contest)

        expect(response.body).to include(judge_user.email)
      end
    end

    context "when authenticated as non-owner" do
      before { sign_in other_organizer }

      it "redirects with alert" do
        get organizers_contest_judges_path(contest)
        expect(response).to redirect_to(organizers_contests_path)
        expect(flash[:alert]).to eq("この操作を行う権限がありません。")
      end
    end
  end

  describe "POST /organizers/contests/:contest_id/judges" do
    let(:valid_params) { { contest_judge: { user_id: judge_user.id } } }

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      context "with valid params" do
        it "creates a new contest judge" do
          expect {
            post organizers_contest_judges_path(contest), params: valid_params
          }.to change(ContestJudge, :count).by(1)
        end

        it "redirects to judges index" do
          post organizers_contest_judges_path(contest), params: valid_params
          expect(response).to redirect_to(organizers_contest_judges_path(contest))
        end

        it "sets invited_at" do
          post organizers_contest_judges_path(contest), params: valid_params
          expect(ContestJudge.last.invited_at).to be_present
        end
      end

      context "with invalid params (duplicate user)" do
        before { create(:contest_judge, contest: contest, user: judge_user) }

        it "does not create a duplicate judge" do
          expect {
            post organizers_contest_judges_path(contest), params: valid_params
          }.not_to change(ContestJudge, :count)
        end

        it "renders index with unprocessable_entity" do
          post organizers_contest_judges_path(contest), params: valid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when authenticated as non-owner" do
      before { sign_in other_organizer }

      it "redirects with alert" do
        post organizers_contest_judges_path(contest), params: valid_params
        expect(response).to redirect_to(organizers_contests_path)
      end
    end
  end

  describe "DELETE /organizers/contests/:contest_id/judges/:id" do
    let!(:contest_judge) { create(:contest_judge, contest: contest, user: judge_user) }

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "deletes the contest judge" do
        expect {
          delete organizers_contest_judge_path(contest, contest_judge)
        }.to change(ContestJudge, :count).by(-1)
      end

      it "redirects to judges index" do
        delete organizers_contest_judge_path(contest, contest_judge)
        expect(response).to redirect_to(organizers_contest_judges_path(contest))
      end
    end

    context "when authenticated as non-owner" do
      before { sign_in other_organizer }

      it "redirects with alert" do
        delete organizers_contest_judge_path(contest, contest_judge)
        expect(response).to redirect_to(organizers_contests_path)
      end

      it "does not delete the judge" do
        expect {
          delete organizers_contest_judge_path(contest, contest_judge)
        }.not_to change(ContestJudge, :count)
      end
    end
  end
end
