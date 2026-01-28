# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Gallery", type: :request do
  describe "GET /gallery" do
    let!(:published_contest) { create(:contest, :published) }
    let!(:finished_contest) { create(:contest, :published) }
    let!(:draft_contest) { create(:contest, :draft) }

    let!(:entry1) { create(:entry, contest: published_contest, title: "Published Entry 1") }
    let!(:entry2) { create(:entry, contest: published_contest, title: "Published Entry 2") }
    let!(:entry3) { create(:entry, contest: finished_contest, title: "Finished Entry") }

    before do
      # Finish the contest after entries are created
      finished_contest.finish!
    end

    it "returns successful response" do
      get gallery_index_path
      expect(response).to have_http_status(:success)
    end

    it "displays entries from published contests" do
      get gallery_index_path
      expect(response.body).to include("Published Entry 1")
      expect(response.body).to include("Published Entry 2")
    end

    it "displays entries from finished contests" do
      get gallery_index_path
      expect(response.body).to include("Finished Entry")
    end

    describe "filtering by contest" do
      it "filters entries by contest_id" do
        get gallery_index_path, params: { contest_id: published_contest.id }
        expect(response.body).to include("Published Entry 1")
        expect(response.body).to include("Published Entry 2")
        expect(response.body).not_to include("Finished Entry")
      end
    end

    describe "sorting" do
      it "sorts by newest by default" do
        get gallery_index_path
        expect(response).to have_http_status(:success)
      end

      it "sorts by popular" do
        # Add votes to entry2
        user1 = create(:user, :confirmed)
        user2 = create(:user, :confirmed)
        create(:vote, entry: entry2, user: user1)
        create(:vote, entry: entry2, user: user2)

        get gallery_index_path, params: { sort: "popular" }
        expect(response).to have_http_status(:success)
      end

      it "sorts by oldest" do
        get gallery_index_path, params: { sort: "oldest" }
        expect(response).to have_http_status(:success)
      end
    end

    describe "pagination" do
      before do
        # Create many entries
        20.times { create(:entry, contest: published_contest) }
      end

      it "paginates results" do
        get gallery_index_path
        expect(response).to have_http_status(:success)
      end

      it "shows page 2" do
        get gallery_index_path, params: { page: 2 }
        expect(response).to have_http_status(:success)
      end
    end

    describe "contest list for filter" do
      it "includes published contests in filter dropdown" do
        get gallery_index_path
        expect(response.body).to include(published_contest.title)
      end

      it "includes finished contests in filter dropdown" do
        get gallery_index_path
        expect(response.body).to include(finished_contest.title)
      end
    end

    describe "moderation visibility filtering" do
      let!(:pending_entry) { create(:entry, contest: published_contest, title: "Pending Entry", moderation_status: :moderation_pending) }
      let!(:approved_entry) { create(:entry, contest: published_contest, title: "Approved Entry", moderation_status: :moderation_approved) }
      let!(:hidden_entry) { create(:entry, contest: published_contest, title: "Hidden Entry", moderation_status: :moderation_hidden) }
      let!(:review_entry) { create(:entry, contest: published_contest, title: "Review Entry", moderation_status: :moderation_requires_review) }

      it "shows pending entries" do
        get gallery_index_path
        expect(response.body).to include("Pending Entry")
      end

      it "shows approved entries" do
        get gallery_index_path
        expect(response.body).to include("Approved Entry")
      end

      it "does not show hidden entries" do
        get gallery_index_path
        expect(response.body).not_to include("Hidden Entry")
      end

      it "does not show entries requiring review" do
        get gallery_index_path
        expect(response.body).not_to include("Review Entry")
      end
    end
  end
end
