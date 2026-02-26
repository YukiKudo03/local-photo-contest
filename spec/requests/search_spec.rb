# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Search", type: :request do
  let!(:published_contest) { create(:contest, :published, title: "桜フォトコンテスト", description: "桜の写真を募集", theme: "春の風景") }
  let!(:finished_contest) { create(:contest, :published, title: "夏祭りコンテスト", description: "祭りの写真") }
  let!(:draft_contest) { create(:contest, :draft, title: "下書きコンテスト") }

  let!(:entry1) { create(:entry, contest: published_contest, title: "満開の桜", description: "公園の桜") }
  let!(:entry2) { create(:entry, contest: finished_contest, title: "花火大会", description: "夏祭りの花火") }

  let!(:spot1) { create(:spot, contest: published_contest, name: "上野公園", address: "東京都台東区", description: "桜の名所") }
  let!(:spot2) { create(:spot, contest: finished_contest, name: "隅田川", address: "東京都墨田区") }

  before do
    finished_contest.update_column(:status, Contest.statuses[:finished])
  end

  describe "GET /search" do
    context "without query" do
      it "renders the search page" do
        get search_path
        expect(response).to have_http_status(:success)
      end

      it "shows zero results" do
        get search_path
        expect(response.body).to include("キーワードを入力してください")
      end
    end

    context "with query" do
      it "returns matching contests" do
        get search_path, params: { q: "桜" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("桜フォトコンテスト")
        expect(response.body).not_to include("夏祭りコンテスト")
      end

      it "returns matching entries" do
        get search_path, params: { q: "花火" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("花火大会")
      end

      it "returns matching spots" do
        get search_path, params: { q: "上野" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("上野公園")
      end

      it "does not return draft contests" do
        get search_path, params: { q: "下書き" }
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include("下書きコンテスト")
      end

      it "shows total count" do
        get search_path, params: { q: "桜" }
        expect(response.body).to include("検索結果")
      end
    end

    context "with type filter" do
      it "filters by contests" do
        get search_path, params: { q: "桜", type: "contests" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("桜フォトコンテスト")
      end

      it "filters by entries" do
        get search_path, params: { q: "桜", type: "entries" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("満開の桜")
      end

      it "filters by spots" do
        get search_path, params: { q: "上野", type: "spots" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("上野公園")
      end
    end

    context "with no results" do
      it "shows no results message" do
        get search_path, params: { q: "存在しないキーワード" }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("検索結果がありません")
      end
    end

    context "with empty query string" do
      it "treats blank query as no search" do
        get search_path, params: { q: "   " }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("キーワードを入力してください")
      end
    end
  end
end
