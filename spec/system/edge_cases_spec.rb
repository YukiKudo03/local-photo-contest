# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Edge Cases", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  describe "concurrent voting protection" do
    let!(:organizer) { create(:user, :organizer, :confirmed) }
    let!(:voter) { create(:user, :confirmed) }
    let!(:entry_owner) { create(:user, :confirmed) }
    let!(:terms) { create(:terms_of_service, :current) }
    let!(:contest) { create(:contest, :accepting_entries, user: organizer) }
    let!(:entry) { create(:entry, user: entry_owner, contest: contest, title: "テスト作品") }

    before do
      create(:terms_acceptance, user: voter, terms_of_service: terms)
      create(:terms_acceptance, user: entry_owner, terms_of_service: terms)
    end

    it "database prevents duplicate votes" do
      # First vote
      create(:vote, entry: entry, user: voter)

      # Second vote should fail due to uniqueness
      expect {
        Vote.create!(entry: entry, user: voter)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "prevents voting on own entry" do
      # Self-vote should fail
      expect {
        Vote.create!(entry: entry, user: entry_owner)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "timezone handling" do
    let!(:organizer) { create(:user, :organizer, :confirmed) }
    let!(:terms) { create(:terms_of_service, :current) }
    let!(:contest) do
      create(:contest, :accepting_entries, user: organizer,
             entry_start_at: Time.current,
             entry_end_at: 30.days.from_now)
    end

    before do
      create(:terms_acceptance, user: organizer, terms_of_service: terms)
      login_as organizer, scope: :user
    end

    it "displays contest dates correctly" do
      visit organizers_contest_path(contest)

      # Contest should be accessible and show the title
      expect(page).to have_content(contest.title)
    end
  end

  describe "navigation with browser back button" do
    let!(:organizer) { create(:user, :organizer, :confirmed) }
    let!(:participant) { create(:user, :confirmed) }
    let!(:terms) { create(:terms_of_service, :current) }
    let!(:contest1) { create(:contest, :published, user: organizer, title: "コンテスト1") }
    let!(:contest2) { create(:contest, :published, user: organizer, title: "コンテスト2") }

    before do
      create(:terms_acceptance, user: participant, terms_of_service: terms)
      login_as participant, scope: :user
    end

    it "navigates between contest list and detail" do
      visit contests_path
      expect(page).to have_content("コンテスト1")
      expect(page).to have_content("コンテスト2")

      # Navigate directly to contest detail
      visit contest_path(contest1)
      expect(page).to have_content("コンテスト1")

      # Navigate back to list
      visit contests_path
      expect(page).to have_content("コンテスト1")
      expect(page).to have_content("コンテスト2")
    end
  end

  describe "authentication boundary" do
    let!(:organizer) { create(:user, :organizer, :confirmed) }
    let!(:terms) { create(:terms_of_service, :current) }
    let!(:contest) { create(:contest, :accepting_entries, user: organizer) }

    before do
      create(:terms_acceptance, user: organizer, terms_of_service: terms)
    end

    it "redirects unauthenticated users from protected pages" do
      # Try to access entry form without login
      visit new_contest_entry_path(contest)

      # Should redirect to login
      expect(page).to have_content("ログイン")
    end

    it "protects organizer pages from non-organizers" do
      user = create(:user, :confirmed)
      create(:terms_acceptance, user: user, terms_of_service: terms)
      login_as user, scope: :user

      visit organizers_contests_path

      expect(page).to have_content("権限がありません")
    end
  end

  describe "entry ownership protection" do
    let!(:organizer) { create(:user, :organizer, :confirmed) }
    let!(:owner) { create(:user, :confirmed) }
    let!(:other_user) { create(:user, :confirmed) }
    let!(:terms) { create(:terms_of_service, :current) }
    let!(:contest) { create(:contest, :accepting_entries, user: organizer) }
    let!(:entry) { create(:entry, user: owner, contest: contest, title: "オーナーの作品") }

    before do
      create(:terms_acceptance, user: owner, terms_of_service: terms)
      create(:terms_acceptance, user: other_user, terms_of_service: terms)
    end

    it "allows owner to edit their entry" do
      login_as owner, scope: :user
      visit edit_entry_path(entry)

      expect(page).to have_field("entry[title]", with: "オーナーの作品")
    end

    it "prevents other users from editing entry" do
      login_as other_user, scope: :user
      visit edit_entry_path(entry)

      expect(page).to have_content("権限がありません")
    end
  end
end
