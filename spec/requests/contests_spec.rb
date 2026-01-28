require 'rails_helper'

RSpec.describe "Contests", type: :request do
  let(:organizer) { create(:user, :organizer) }

  describe "GET /contests" do
    it "returns success" do
      get contests_path
      expect(response).to have_http_status(:success)
    end

    it "displays only published and finished contests" do
      draft_contest = create(:contest, :draft, user: organizer, title: "下書きコンテスト")
      published_contest = create(:contest, :published, user: organizer, title: "公開コンテスト")
      finished_contest = create(:contest, :finished, user: organizer, title: "終了コンテスト")

      get contests_path

      expect(response.body).not_to include("下書きコンテスト")
      expect(response.body).to include("公開コンテスト")
      expect(response.body).to include("終了コンテスト")
    end

    it "does not display deleted contests" do
      deleted_contest = create(:contest, :deleted, user: organizer, title: "削除されたコンテスト")

      get contests_path

      expect(response.body).not_to include("削除されたコンテスト")
    end
  end

  describe "GET /contests/:id" do
    context "with published contest" do
      let(:contest) { create(:contest, :published, user: organizer) }

      it "returns success" do
        get contest_path(contest)
        expect(response).to have_http_status(:success)
      end
    end

    context "with finished contest" do
      let(:contest) { create(:contest, :finished, user: organizer) }

      it "returns success" do
        get contest_path(contest)
        expect(response).to have_http_status(:success)
      end
    end

    context "with draft contest" do
      let(:contest) { create(:contest, :draft, user: organizer) }

      it "returns not found" do
        get contest_path(contest)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with deleted contest" do
      let(:contest) { create(:contest, :deleted, user: organizer) }

      it "returns not found" do
        get contest_path(contest)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
