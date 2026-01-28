# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::JudgingSettings", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:other_organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :draft, user: organizer) }

  describe "GET /organizers/contests/:contest_id/judging_settings/edit" do
    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "returns success" do
        get edit_organizers_contest_judging_settings_path(contest)
        expect(response).to have_http_status(:success)
      end

      it "displays current judging settings" do
        contest.update!(judging_method: :hybrid, judge_weight: 60)
        get edit_organizers_contest_judging_settings_path(contest)
        expect(response.body).to include("ハイブリッド")
      end
    end

    context "when authenticated as different organizer" do
      before { sign_in other_organizer }

      it "redirects with unauthorized message" do
        get edit_organizers_contest_judging_settings_path(contest)
        expect(response).to redirect_to(organizers_contests_path)
        follow_redirect!
        expect(response.body).to include("この操作を行う権限がありません")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get edit_organizers_contest_judging_settings_path(contest)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /organizers/contests/:contest_id/judging_settings" do
    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "updates judging method to vote_only" do
        patch organizers_contest_judging_settings_path(contest), params: {
          contest: { judging_method: "vote_only" }
        }

        expect(response).to redirect_to(edit_organizers_contest_judging_settings_path(contest))
        expect(contest.reload.judging_method).to eq("vote_only")
      end

      it "updates judging method to hybrid with weight" do
        patch organizers_contest_judging_settings_path(contest), params: {
          contest: { judging_method: "hybrid", judge_weight: 60 }
        }

        expect(response).to redirect_to(edit_organizers_contest_judging_settings_path(contest))
        contest.reload
        expect(contest.judging_method).to eq("hybrid")
        expect(contest.judge_weight).to eq(60)
      end

      it "updates prize_count" do
        patch organizers_contest_judging_settings_path(contest), params: {
          contest: { prize_count: 5 }
        }

        expect(contest.reload.prize_count).to eq(5)
      end

      it "updates show_detailed_scores" do
        patch organizers_contest_judging_settings_path(contest), params: {
          contest: { show_detailed_scores: true }
        }

        expect(contest.reload.show_detailed_scores).to be true
      end

      context "with invalid parameters" do
        it "renders edit with errors for invalid judge_weight" do
          patch organizers_contest_judging_settings_path(contest), params: {
            contest: { judge_weight: 150 }
          }

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "renders edit with errors for invalid prize_count" do
          patch organizers_contest_judging_settings_path(contest), params: {
            contest: { prize_count: 100 }
          }

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when authenticated as different organizer" do
      before { sign_in other_organizer }

      it "redirects with unauthorized message" do
        patch organizers_contest_judging_settings_path(contest), params: {
          contest: { judging_method: "vote_only" }
        }

        expect(response).to redirect_to(organizers_contests_path)
        expect(contest.reload.judging_method).to eq("judge_only") # default, unchanged
      end
    end
  end
end
