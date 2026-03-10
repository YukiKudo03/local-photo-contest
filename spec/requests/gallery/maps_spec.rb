# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Gallery::Maps", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:organizer) { create(:user, :organizer, :confirmed) }

  describe "GET /gallery/map" do
    before { sign_in user }

    it "returns success" do
      get map_gallery_index_path
      expect(response).to have_http_status(:success)
    end

    context "with entries that have coordinates" do
      let(:contest) { create(:contest, :published, user: organizer) }
      let(:spot) { create(:spot, :with_coordinates, contest: contest) }
      let!(:entry) { create(:entry, contest: contest, user: user, spot: spot) }

      it "includes entries with location" do
        get map_gallery_index_path
        expect(response).to have_http_status(:success)
      end
    end

    context "with entries without coordinates" do
      let(:contest) { create(:contest, :published, user: organizer) }
      let!(:entry) { create(:entry, contest: contest, user: user, spot: nil) }

      it "includes entries without location" do
        get map_gallery_index_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /gallery/map/data" do
    before { sign_in user }

    it "returns JSON data" do
      get map_data_gallery_index_path, as: :json
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("application/json")
    end

    context "with entries that have coordinates" do
      let(:contest) { create(:contest, :published, user: organizer) }
      let(:spot) { create(:spot, :with_coordinates, contest: contest) }
      let!(:entry) { create(:entry, contest: contest, user: user, spot: spot) }

      it "returns marker data for entries with coordinates" do
        get map_data_gallery_index_path, as: :json
        expect(response).to have_http_status(:success)
      end
    end
  end
end
