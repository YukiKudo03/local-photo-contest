# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Participant Flow", type: :system do
  let!(:organizer) { create(:user, :organizer, :confirmed) }
  let!(:participant) { create(:user, :confirmed) }
  let!(:terms) { create(:terms_of_service, :current) }
  let!(:contest) { create(:contest, :accepting_entries, user: organizer, title: "春の写真コンテスト", theme: "桜") }

  before do
    create(:terms_acceptance, user: participant, terms_of_service: terms)
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    driven_by(:selenium_chrome_headless)
  end

  describe "browsing contests" do
    it "shows published contests on the public list" do
      visit contests_path

      expect(page).to have_content("春の写真コンテスト")
    end

    it "shows contest details" do
      visit contest_path(contest)

      expect(page).to have_content("春の写真コンテスト")
      expect(page).to have_content("桜")
    end
  end

  describe "viewing gallery" do
    it "shows gallery page" do
      visit gallery_index_path

      expect(page).to have_content("ギャラリー")
    end
  end

  describe "managing own entries" do
    let!(:entry) { create(:entry, user: participant, contest: contest, title: "私の作品") }

    before { login_as participant, scope: :user }

    it "shows list of own entries" do
      visit my_entries_path

      expect(page).to have_content("私の作品")
    end

    it "shows entry detail" do
      visit entry_path(entry)

      expect(page).to have_content("私の作品")
    end
  end

  describe "viewing contest results" do
    let!(:finished_contest) do
      create(:contest, :finished, user: organizer, title: "結果発表コンテスト", results_announced_at: Time.current)
    end

    it "shows contest results page" do
      visit contest_results_path(finished_contest)

      expect(page).to have_content("結果")
    end
  end

  describe "profile management" do
    before { login_as participant, scope: :user }

    it "shows profile page" do
      visit my_profile_path

      expect(page).to have_content(participant.email)
    end

    it "shows edit profile page" do
      visit edit_my_profile_path

      expect(page).to have_content("プロフィール編集")
    end
  end
end
