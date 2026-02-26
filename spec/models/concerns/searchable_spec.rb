# frozen_string_literal: true

require "rails_helper"

RSpec.describe Searchable do
  describe "Contest.search" do
    let!(:published_contest) { create(:contest, :published, title: "桜フォトコンテスト", theme: "春の風景") }
    let!(:other_contest) { create(:contest, :published, title: "夏祭りコンテスト", theme: "夏の思い出") }

    it "finds contests by title" do
      results = Contest.search("桜")
      expect(results).to include(published_contest)
      expect(results).not_to include(other_contest)
    end

    it "finds contests by theme" do
      results = Contest.search("春の風景")
      expect(results).to include(published_contest)
      expect(results).not_to include(other_contest)
    end

    it "returns all records for blank query" do
      expect(Contest.search("")).to include(published_contest, other_contest)
      expect(Contest.search(nil)).to include(published_contest, other_contest)
    end

    it "performs partial matching" do
      results = Contest.search("フォト")
      expect(results).to include(published_contest)
    end
  end

  describe "Entry.search" do
    let!(:contest) { create(:contest, :published) }
    let!(:entry1) { create(:entry, contest: contest, title: "桜の写真", description: "公園で撮影") }
    let!(:entry2) { create(:entry, contest: contest, title: "海の写真", location: "湘南海岸") }

    it "finds entries by title" do
      results = Entry.search("桜")
      expect(results).to include(entry1)
      expect(results).not_to include(entry2)
    end

    it "finds entries by description" do
      results = Entry.search("公園")
      expect(results).to include(entry1)
    end

    it "finds entries by location" do
      results = Entry.search("湘南")
      expect(results).to include(entry2)
    end
  end

  describe "Spot.search" do
    let!(:contest) { create(:contest, :published) }
    let!(:spot1) { create(:spot, contest: contest, name: "上野公園", address: "東京都台東区") }
    let!(:spot2) { create(:spot, contest: contest, name: "浅草寺", address: "東京都台東区浅草") }

    it "finds spots by name" do
      results = Spot.search("上野")
      expect(results).to include(spot1)
      expect(results).not_to include(spot2)
    end

    it "finds spots by address" do
      results = Spot.search("浅草")
      expect(results).to include(spot2)
    end
  end
end
