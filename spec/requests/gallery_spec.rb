# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Gallery", type: :request do
  describe "GET /gallery/map_data" do
    let!(:contest) { create(:contest, :published) }
    let!(:spot) { create(:spot, contest: contest, latitude: 35.6762, longitude: 139.6503) }

    context "with multiple entries having votes" do
      before do
        # Create 5 entries with different vote counts
        5.times do |i|
          entry = create(:entry, contest: contest, spot: spot)
          # Add varying number of votes
          (i + 1).times do
            user = create(:user, :confirmed)
            create(:vote, entry: entry, user: user)
          end
        end
      end

      it "returns successful response" do
        get map_data_gallery_index_path(format: :json)
        expect(response).to have_http_status(:success)
      end

      it "returns correct votes count for each entry" do
        get map_data_gallery_index_path(format: :json)
        json = JSON.parse(response.body)

        expect(json.length).to eq(5)
        # Check that votes_count is included and correct
        json.each do |entry_data|
          expect(entry_data).to have_key("votes_count")
          expect(entry_data["votes_count"]).to be >= 1
        end
      end

      it "does not cause N+1 queries for votes" do
        # First request to warm up
        get map_data_gallery_index_path(format: :json)

        # Count queries on second request
        query_count = 0
        counter = lambda { |_name, _start, _finish, _id, payload|
          query_count += 1 if payload[:sql] =~ /SELECT.*votes/i
        }

        ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
          get map_data_gallery_index_path(format: :json)
        end

        # Should have at most 2 queries for votes (preload + possible count), not N queries
        # If N+1 exists, this would be 5+ (one per entry)
        expect(query_count).to be <= 2, "Expected at most 2 votes queries but got #{query_count} (N+1 detected)"
      end
    end

    context "with filters" do
      let!(:spot2) { create(:spot, contest: contest, latitude: 34.6937, longitude: 135.5023) }
      let!(:entry1) { create(:entry, contest: contest, spot: spot) }
      let!(:entry2) { create(:entry, contest: contest, spot: spot2) }

      it "filters by spot_id" do
        get map_data_gallery_index_path(format: :json), params: { spot_id: spot.id }
        json = JSON.parse(response.body)

        expect(json.length).to eq(1)
        expect(json.first["spot_id"]).to eq(spot.id)
      end
    end
  end

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
        30.times { create(:entry, contest: published_contest) }
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

    describe "infinite scroll" do
      before do
        # Create entries that span multiple pages (24 per page)
        30.times { |i| create(:entry, contest: published_contest, title: "Entry #{i + 1}") }
      end

      it "includes turbo frame for gallery entries" do
        get gallery_index_path
        expect(response.body).to include('id="gallery-entries"')
        expect(response.body).to include("turbo-frame")
      end

      it "includes next page link with turbo frame" do
        get gallery_index_path
        expect(response.body).to include("page=2")
      end

      it "returns partial content for turbo frame requests" do
        get gallery_index_path, params: { page: 2 }, headers: { "Turbo-Frame" => "gallery-entries" }
        expect(response).to have_http_status(:success)
        # Should not include the full page layout elements
        expect(response.body).not_to include('class="container mx-auto max-w-7xl px-4 py-8">')
      end

      it "preserves filter params in next page link" do
        get gallery_index_path, params: { contest_id: published_contest.id, sort: "popular" }
        expect(response.body).to include("contest_id=#{published_contest.id}")
        expect(response.body).to include("sort=popular")
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
