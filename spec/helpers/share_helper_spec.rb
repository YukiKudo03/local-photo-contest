# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShareHelper, type: :helper do
  describe "#twitter_share_url" do
    it "returns a Twitter intent URL with text and url" do
      url = helper.twitter_share_url(text: "Hello", url: "https://example.com")
      expect(url).to start_with("https://twitter.com/intent/tweet?")
      expect(url).to include("text=Hello")
      expect(url).to include("url=https")
    end

    it "includes hashtags when provided" do
      url = helper.twitter_share_url(text: "Hello", url: "https://example.com", hashtags: %w[photo contest])
      expect(url).to include("hashtags=photo%2Ccontest")
    end

    it "omits hashtags when empty" do
      url = helper.twitter_share_url(text: "Hello", url: "https://example.com", hashtags: [])
      expect(url).not_to include("hashtags")
    end
  end

  describe "#facebook_share_url" do
    it "returns a Facebook sharer URL" do
      url = helper.facebook_share_url(url: "https://example.com/page")
      expect(url).to start_with("https://www.facebook.com/sharer/sharer.php?u=")
      expect(url).to include("example.com")
    end
  end

  describe "#line_share_url" do
    it "returns a LINE share URL with text and url" do
      url = helper.line_share_url(text: "Check this out", url: "https://example.com")
      expect(url).to start_with("https://social-plugins.line.me/lineit/share?")
      expect(url).to include("example.com")
      expect(url).to include("Check")
    end
  end

  describe "#contest_results_share_data" do
    let(:organizer) { create(:user, :organizer, :confirmed) }
    let(:contest) { create(:contest, :finished, user: organizer, results_announced_at: 1.day.ago) }

    it "returns share data with title, text, url, and hashtags" do
      data = helper.contest_results_share_data(contest)
      expect(data[:title]).to include("結果発表")
      expect(data[:text]).to include(contest.title)
      expect(data[:url]).to be_present
      expect(data[:hashtags]).to include("結果発表")
    end
  end

  describe "#award_share_data" do
    let(:organizer) { create(:user, :organizer, :confirmed) }
    let(:contest) { create(:contest, :published, user: organizer) }
    let(:entry) { create(:entry, contest: contest) }

    it "returns share data for an award winner" do
      data = helper.award_share_data(entry, "最優秀賞")
      expect(data[:title]).to include("最優秀賞")
      expect(data[:text]).to include("最優秀賞")
      expect(data[:text]).to include("受賞")
      expect(data[:hashtags]).to include("受賞")
    end
  end
end
