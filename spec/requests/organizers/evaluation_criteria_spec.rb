# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::EvaluationCriteria", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:other_organizer) { create(:user, :organizer, :confirmed) }
  let(:terms) { create(:terms_of_service, :current) }
  let(:contest) { create(:contest, :published, user: organizer) }

  before do
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    create(:terms_acceptance, user: other_organizer, terms_of_service: terms)
  end

  describe "GET /organizers/contests/:contest_id/evaluation_criteria" do
    context "when not authenticated" do
      it "redirects to login" do
        get organizers_contest_evaluation_criteria_path(contest)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "returns success" do
        get organizers_contest_evaluation_criteria_path(contest)
        expect(response).to have_http_status(:success)
      end

      it "lists all criteria" do
        criterion = create(:evaluation_criterion, contest: contest, name: "構図")

        get organizers_contest_evaluation_criteria_path(contest)

        expect(response.body).to include("構図")
      end
    end

    context "when authenticated as non-owner" do
      before { sign_in other_organizer }

      it "redirects with alert" do
        get organizers_contest_evaluation_criteria_path(contest)
        expect(response).to redirect_to(organizers_contests_path)
        expect(flash[:alert]).to eq("この操作を行う権限がありません。")
      end
    end
  end

  describe "GET /organizers/contests/:contest_id/evaluation_criteria/new" do
    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "returns success" do
        get new_organizers_contest_evaluation_criterium_path(contest)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /organizers/contests/:contest_id/evaluation_criteria" do
    let(:valid_params) do
      {
        evaluation_criterion: {
          name: "構図",
          description: "写真の構図を評価します",
          max_score: 10,
          position: 1
        }
      }
    end
    let(:invalid_params) { { evaluation_criterion: { name: "" } } }

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      context "with valid params" do
        it "creates a new evaluation criterion" do
          expect {
            post organizers_contest_evaluation_criteria_path(contest), params: valid_params
          }.to change(EvaluationCriterion, :count).by(1)
        end

        it "redirects to criteria index" do
          post organizers_contest_evaluation_criteria_path(contest), params: valid_params
          expect(response).to redirect_to(organizers_contest_evaluation_criteria_path(contest))
        end
      end

      context "with invalid params" do
        it "does not create a criterion" do
          expect {
            post organizers_contest_evaluation_criteria_path(contest), params: invalid_params
          }.not_to change(EvaluationCriterion, :count)
        end

        it "renders new with unprocessable_entity" do
          post organizers_contest_evaluation_criteria_path(contest), params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when results are announced" do
        let(:contest) { create(:contest, :finished, user: organizer, results_announced_at: Time.current) }

        it "redirects with alert" do
          post organizers_contest_evaluation_criteria_path(contest), params: valid_params
          expect(response).to redirect_to(organizers_contest_evaluation_criteria_path(contest))
          expect(flash[:alert]).to eq("結果発表後は評価基準を変更できません。")
        end
      end
    end

    context "when authenticated as non-owner" do
      before { sign_in other_organizer }

      it "redirects with alert" do
        post organizers_contest_evaluation_criteria_path(contest), params: valid_params
        expect(response).to redirect_to(organizers_contests_path)
      end
    end
  end

  describe "GET /organizers/contests/:contest_id/evaluation_criteria/:id/edit" do
    let!(:criterion) { create(:evaluation_criterion, contest: contest) }

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "returns success" do
        get edit_organizers_contest_evaluation_criterium_path(contest, criterion)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "PATCH /organizers/contests/:contest_id/evaluation_criteria/:id" do
    let!(:criterion) { create(:evaluation_criterion, contest: contest, name: "旧名前") }
    let(:valid_params) { { evaluation_criterion: { name: "新名前" } } }

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      context "with valid params" do
        it "updates the criterion" do
          patch organizers_contest_evaluation_criterium_path(contest, criterion), params: valid_params
          expect(criterion.reload.name).to eq("新名前")
        end

        it "redirects to criteria index" do
          patch organizers_contest_evaluation_criterium_path(contest, criterion), params: valid_params
          expect(response).to redirect_to(organizers_contest_evaluation_criteria_path(contest))
        end
      end

      context "with invalid params" do
        it "renders edit with unprocessable_entity" do
          patch organizers_contest_evaluation_criterium_path(contest, criterion),
                params: { evaluation_criterion: { name: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when results are announced" do
        let(:contest) { create(:contest, :finished, user: organizer, results_announced_at: Time.current) }
        let!(:criterion) { create(:evaluation_criterion, contest: contest) }

        it "redirects with alert" do
          patch organizers_contest_evaluation_criterium_path(contest, criterion), params: valid_params
          expect(response).to redirect_to(organizers_contest_evaluation_criteria_path(contest))
          expect(flash[:alert]).to eq("結果発表後は評価基準を変更できません。")
        end
      end
    end
  end

  describe "DELETE /organizers/contests/:contest_id/evaluation_criteria/:id" do
    let!(:criterion) { create(:evaluation_criterion, contest: contest) }

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "deletes the criterion" do
        expect {
          delete organizers_contest_evaluation_criterium_path(contest, criterion)
        }.to change(EvaluationCriterion, :count).by(-1)
      end

      it "redirects to criteria index" do
        delete organizers_contest_evaluation_criterium_path(contest, criterion)
        expect(response).to redirect_to(organizers_contest_evaluation_criteria_path(contest))
      end

      context "when results are announced" do
        let(:contest) { create(:contest, :finished, user: organizer, results_announced_at: Time.current) }
        let!(:criterion) { create(:evaluation_criterion, contest: contest) }

        it "does not delete the criterion" do
          expect {
            delete organizers_contest_evaluation_criterium_path(contest, criterion)
          }.not_to change(EvaluationCriterion, :count)
        end

        it "redirects with alert" do
          delete organizers_contest_evaluation_criterium_path(contest, criterion)
          expect(response).to redirect_to(organizers_contest_evaluation_criteria_path(contest))
          expect(flash[:alert]).to eq("結果発表後は評価基準を変更できません。")
        end
      end
    end

    context "when authenticated as non-owner" do
      before { sign_in other_organizer }

      it "does not delete the criterion" do
        expect {
          delete organizers_contest_evaluation_criterium_path(contest, criterion)
        }.not_to change(EvaluationCriterion, :count)
      end
    end
  end
end
