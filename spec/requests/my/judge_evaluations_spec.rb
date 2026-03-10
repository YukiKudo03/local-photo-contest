# frozen_string_literal: true

require "rails_helper"

RSpec.describe "My::JudgeEvaluations", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:judge_user) { create(:user, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }
  let(:contest_judge) { create(:contest_judge, contest: contest, user: judge_user) }
  let(:entry_user) { create(:user, :confirmed) }
  let!(:entry) { create(:entry, contest: contest, user: entry_user) }
  let!(:criterion) { create(:evaluation_criterion, contest: contest) }

  describe "GET /my/judge_assignments/:id/evaluations" do
    context "when signed in as judge" do
      before { sign_in judge_user }

      it "returns success" do
        get my_judge_assignment_evaluations_path(contest_judge)
        expect(response).to have_http_status(:success)
      end
    end

    context "when not signed in" do
      it "redirects to login" do
        get my_judge_assignment_evaluations_path(contest_judge)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /my/judge_assignments/:id/evaluations/:entry_id" do
    before { sign_in judge_user }

    it "returns success" do
      get my_judge_assignment_evaluation_path(contest_judge, entry)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /my/judge_assignments/:id/evaluations" do
    before { sign_in judge_user }

    it "creates evaluations and redirects" do
      post my_judge_assignment_evaluations_path(contest_judge), params: {
        entry_id: entry.id,
        evaluations: { criterion.id.to_s => "8" },
        comment: "Great photo"
      }
      expect(response).to redirect_to(my_judge_assignment_evaluation_path(contest_judge, entry))
    end

    context "when evaluating own entry" do
      let!(:own_entry) { create(:entry, contest: contest, user: judge_user) }

      it "redirects with alert" do
        post my_judge_assignment_evaluations_path(contest_judge), params: {
          entry_id: own_entry.id,
          evaluations: { criterion.id.to_s => "8" }
        }
        expect(response).to redirect_to(my_judge_assignment_path(contest_judge))
      end
    end

    context "when save fails with validation error" do
      it "renders show with error" do
        allow_any_instance_of(JudgeEvaluation).to receive(:save!).and_raise(
          ActiveRecord::RecordInvalid.new(JudgeEvaluation.new)
        )

        post my_judge_assignment_evaluations_path(contest_judge), params: {
          entry_id: entry.id,
          evaluations: { criterion.id.to_s => "8" }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /my/judge_assignments/:id/evaluations/:entry_id" do
    before { sign_in judge_user }

    it "updates evaluations and redirects" do
      patch my_judge_assignment_evaluation_path(contest_judge, entry), params: {
        evaluations: { criterion.id.to_s => "9" },
        comment: "Updated comment"
      }
      expect(response).to redirect_to(my_judge_assignment_evaluation_path(contest_judge, entry))
    end

    context "when update fails with validation error" do
      it "renders show with error" do
        allow_any_instance_of(JudgeEvaluation).to receive(:save!).and_raise(
          ActiveRecord::RecordInvalid.new(JudgeEvaluation.new)
        )

        patch my_judge_assignment_evaluation_path(contest_judge, entry), params: {
          evaluations: { criterion.id.to_s => "9" }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
