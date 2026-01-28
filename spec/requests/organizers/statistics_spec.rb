# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::Statistics", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:other_organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }

  describe "GET /organizers/contests/:contest_id/statistics" do
    context "when not authenticated" do
      it "redirects to login page" do
        get organizers_contest_statistics_path(contest)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "returns success" do
        get organizers_contest_statistics_path(contest)
        expect(response).to have_http_status(:success)
      end

      it "displays contest title" do
        get organizers_contest_statistics_path(contest)
        expect(response.body).to include(contest.title)
      end

      it "displays summary cards section" do
        get organizers_contest_statistics_path(contest)
        expect(response.body).to include("総応募数")
        expect(response.body).to include("総投票数")
        expect(response.body).to include("参加ユーザー数")
        expect(response.body).to include("登録スポット数")
      end

      context "with entries data" do
        let!(:user) { create(:user, :confirmed) }
        let!(:entry) { create(:entry, contest: contest, user: user) }

        it "displays entry count" do
          get organizers_contest_statistics_path(contest)
          expect(response.body).to include("1") # At least one entry
        end
      end

      context "with spots data" do
        let!(:spot) { create(:spot, contest: contest) }
        let!(:user) { create(:user, :confirmed) }
        let!(:entry) { create(:entry, contest: contest, user: user, spot: spot) }

        it "displays spot rankings" do
          get organizers_contest_statistics_path(contest)
          expect(response.body).to include(spot.name)
        end
      end

      context "with votes data" do
        let!(:user1) { create(:user, :confirmed) }
        let!(:user2) { create(:user, :confirmed) }
        let!(:entry) { create(:entry, contest: contest, user: user1) }
        let!(:vote) { create(:vote, entry: entry, user: user2) }

        it "displays vote analysis section" do
          get organizers_contest_statistics_path(contest)
          expect(response.body).to include("投票分析")
        end
      end

      context "when contest is draft" do
        let(:draft_contest) { create(:contest, :draft, user: organizer) }

        it "returns success" do
          get organizers_contest_statistics_path(draft_contest)
          expect(response).to have_http_status(:success)
        end

        it "shows voting not started message" do
          get organizers_contest_statistics_path(draft_contest)
          expect(response.body).to include("投票期間開始後に表示されます")
        end
      end
    end

    context "when authenticated as different organizer" do
      before { sign_in other_organizer }

      it "redirects with unauthorized message" do
        get organizers_contest_statistics_path(contest)
        expect(response).to redirect_to(organizers_contests_path)
      end

      it "sets alert flash message" do
        get organizers_contest_statistics_path(contest)
        expect(flash[:alert]).to eq("このコンテストにアクセスする権限がありません。")
      end
    end

    context "when authenticated as regular user (not organizer)" do
      let(:regular_user) { create(:user, :confirmed) }

      before { sign_in regular_user }

      it "returns forbidden status" do
        get organizers_contest_statistics_path(contest)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
