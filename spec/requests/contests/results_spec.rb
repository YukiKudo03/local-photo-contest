require 'rails_helper'

RSpec.describe "Contests::Results", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:published_contest) { create(:contest, :published, user: organizer) }

  describe "GET /contests/:contest_id/results" do
    context "when results are announced" do
      let(:contest) do
        published_contest.finish!
        published_contest.announce_results!
        published_contest
      end

      it "returns success" do
        get contest_results_path(contest)
        expect(response).to have_http_status(:success)
      end

      it "displays contest title" do
        get contest_results_path(contest)
        expect(response.body).to include(contest.title)
      end

      context "with entries and votes" do
        let!(:entry1) { create(:entry, contest: published_contest, title: "1位の作品") }
        let!(:entry2) { create(:entry, contest: published_contest, title: "2位の作品") }
        let!(:entry3) { create(:entry, contest: published_contest, title: "3位の作品") }

        before do
          # entry1 has 5 votes, entry2 has 3 votes, entry3 has 1 vote
          5.times { create(:vote, entry: entry1) }
          3.times { create(:vote, entry: entry2) }
          create(:vote, entry: entry3)
          published_contest.finish!
          # Calculate rankings before announcing (uses vote_only method by default)
          RankingCalculator.new(published_contest).calculate
          published_contest.announce_results!
        end

        it "displays entries in ranked order" do
          get contest_results_path(published_contest)
          body = response.body
          expect(body.index("1位の作品")).to be < body.index("2位の作品")
          expect(body.index("2位の作品")).to be < body.index("3位の作品")
        end

        it "displays vote counts" do
          get contest_results_path(published_contest)
          expect(response.body).to include("5")
          expect(response.body).to include("3")
        end
      end
    end

    context "when results are not announced" do
      let(:contest) do
        published_contest.finish!
        published_contest
      end

      it "redirects to contest page" do
        get contest_results_path(contest)
        expect(response).to redirect_to(contest_path(contest))
      end

      it "shows alert message" do
        get contest_results_path(contest)
        follow_redirect!
        expect(response.body).to include("結果はまだ発表されていません")
      end
    end

    context "when contest is draft" do
      let(:draft_contest) { create(:contest, :draft, user: organizer) }

      it "returns not found" do
        get contest_results_path(draft_contest)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
