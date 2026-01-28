# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Contest Lifecycle", type: :system do
  let!(:organizer) { create(:user, :organizer, :confirmed, email: "organizer@example.com") }
  let!(:terms) { create(:terms_of_service, :current) }

  before do
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    driven_by(:selenium_chrome_headless)
  end

  describe "contest creation flow" do
    before { login_as organizer, scope: :user }

    it "shows contest creation form" do
      visit new_organizers_contest_path

      expect(page).to have_content("コンテスト")
      expect(page).to have_field("タイトル")
    end
  end

  describe "contest viewing" do
    let!(:draft_contest) { create(:contest, :draft, user: organizer, title: "下書きコンテスト") }
    let!(:published_contest) { create(:contest, :published, user: organizer, title: "公開コンテスト") }

    before { login_as organizer, scope: :user }

    it "shows contest list" do
      visit organizers_contests_path

      expect(page).to have_content("下書きコンテスト")
      expect(page).to have_content("公開コンテスト")
    end

    it "shows contest detail" do
      visit organizers_contest_path(draft_contest)

      expect(page).to have_content("下書きコンテスト")
    end
  end

  describe "contest with entries" do
    let!(:participant) { create(:user, :confirmed) }
    let!(:contest) { create(:contest, :accepting_entries, user: organizer, title: "応募テスト") }
    let!(:entry) { create(:entry, user: participant, contest: contest, title: "テスト作品") }

    before do
      create(:terms_acceptance, user: participant, terms_of_service: terms)
      login_as organizer, scope: :user
    end

    it "shows entries in organizer view" do
      visit organizers_contest_entries_path(contest)

      expect(page).to have_content("テスト作品")
    end

    it "shows entry detail in organizer view" do
      visit organizers_contest_entry_path(contest, entry)

      expect(page).to have_content("テスト作品")
    end
  end

  describe "public contest viewing" do
    let!(:contest) { create(:contest, :published, user: organizer, title: "公開コンテスト") }

    it "shows contest on public page" do
      visit contest_path(contest)

      expect(page).to have_content("公開コンテスト")
    end

    it "shows contest in list" do
      visit contests_path

      expect(page).to have_content("公開コンテスト")
    end
  end
end
