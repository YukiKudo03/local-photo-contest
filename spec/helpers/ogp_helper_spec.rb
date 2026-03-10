# frozen_string_literal: true

require "rails_helper"

RSpec.describe OgpHelper, type: :helper do
  describe "#set_contest_ogp" do
    let(:contest) { create(:contest, :published, title: "テストコンテスト", description: "テスト説明") }

    it "returns OGP hash with contest info" do
      ogp = helper.set_contest_ogp(contest)
      expect(ogp[:title]).to eq("テストコンテスト")
      expect(ogp[:type]).to eq("article")
      expect(ogp[:twitter_card]).to eq("summary")
    end
  end

  describe "#set_contest_results_ogp" do
    let(:contest) { create(:contest, :published, title: "テストコンテスト") }

    it "returns OGP hash with results info" do
      ogp = helper.set_contest_results_ogp(contest)
      expect(ogp[:title]).to include("結果発表")
      expect(ogp[:type]).to eq("article")
    end
  end

  describe "#set_gallery_ogp" do
    it "returns OGP hash for gallery" do
      ogp = helper.set_gallery_ogp
      expect(ogp[:title]).to eq("フォトギャラリー")
      expect(ogp[:type]).to eq("website")
    end
  end
end
