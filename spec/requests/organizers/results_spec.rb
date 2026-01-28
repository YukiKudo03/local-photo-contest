# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::Results", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:other_organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }

  describe "GET /organizers/contests/:contest_id/results/preview" do
    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "returns success" do
        get preview_organizers_contest_results_path(contest)
        expect(response).to have_http_status(:success)
      end

      context "with entries" do
        let!(:entry1) { create(:entry, contest: contest) }
        let!(:entry2) { create(:entry, contest: contest) }

        before do
          create_list(:vote, 3, entry: entry1)
          create(:vote, entry: entry2)
        end

        it "displays preview with entries" do
          get preview_organizers_contest_results_path(contest)
          expect(response.body).to include(entry1.user.email)
          expect(response.body).to include(entry2.user.email)
        end
      end
    end

    context "when authenticated as different organizer" do
      before { sign_in other_organizer }

      it "redirects with unauthorized message" do
        get preview_organizers_contest_results_path(contest)
        expect(response).to redirect_to(organizers_contests_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get preview_organizers_contest_results_path(contest)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /organizers/contests/:contest_id/results/calculate" do
    let!(:entry1) { create(:entry, contest: contest) }
    let!(:entry2) { create(:entry, contest: contest) }

    before do
      create_list(:vote, 5, entry: entry1)
      create_list(:vote, 3, entry: entry2)
    end

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "calculates and saves rankings" do
        expect {
          post calculate_organizers_contest_results_path(contest)
        }.to change { contest.calculated_rankings.count }.from(0).to(2)

        expect(response).to redirect_to(preview_organizers_contest_results_path(contest))
        follow_redirect!
        expect(response.body).to include("ランキングを計算しました")
      end

      it "creates rankings in correct order" do
        post calculate_organizers_contest_results_path(contest)

        rankings = contest.calculated_rankings.order(:rank)
        expect(rankings.first.entry).to eq(entry1)
        expect(rankings.first.rank).to eq(1)
        expect(rankings.last.entry).to eq(entry2)
        expect(rankings.last.rank).to eq(2)
      end
    end

    context "when authenticated as different organizer" do
      before { sign_in other_organizer }

      it "redirects with unauthorized message" do
        post calculate_organizers_contest_results_path(contest)
        expect(response).to redirect_to(organizers_contests_path)
      end
    end
  end

  describe "POST /organizers/contests/:contest_id/results/announce" do
    let(:published_contest) { create(:contest, :published, user: organizer) }
    let!(:entry) { create(:entry, contest: published_contest) }

    before do
      create(:vote, entry: entry)
      published_contest.finish!
      RankingCalculator.new(published_contest).calculate
    end

    let(:finished_contest) { published_contest }

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "announces results" do
        post announce_organizers_contest_results_path(finished_contest)

        expect(response).to redirect_to(organizers_contest_path(finished_contest))
        follow_redirect!
        expect(response.body).to include("結果を発表しました")
        expect(finished_contest.reload.results_announced?).to be true
      end

      context "when contest is not finished" do
        it "redirects with error" do
          post announce_organizers_contest_results_path(contest)

          expect(response).to redirect_to(preview_organizers_contest_results_path(contest))
          expect(flash[:alert]).to include("終了していません")
        end
      end
    end

    context "when authenticated as different organizer" do
      before { sign_in other_organizer }

      it "redirects with unauthorized message" do
        post announce_organizers_contest_results_path(finished_contest)
        expect(response).to redirect_to(organizers_contests_path)
      end
    end
  end
end
