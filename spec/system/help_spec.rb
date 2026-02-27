# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Help Pages", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  describe "help index page" do
    it "displays all guide cards" do
      visit help_path

      expect(page).to have_content("利用ガイド")
      expect(page).to have_content("参加者向けマニュアル")
      expect(page).to have_content("主催者向けマニュアル")
      expect(page).to have_content("審査員向けマニュアル")
      expect(page).to have_content("管理者向けマニュアル")
    end

    it "navigates to participant guide when clicking the card" do
      visit help_path

      click_link "参加者向けマニュアル"

      expect(page).to have_current_path(help_guide_path(:participant))
      expect(page).to have_content("参加者向けマニュアル")
    end

    it "navigates to organizer guide when clicking the card" do
      visit help_path

      click_link "主催者向けマニュアル"

      expect(page).to have_current_path(help_guide_path(:organizer))
    end

    it "navigates to judge guide when clicking the card" do
      visit help_path

      click_link "審査員向けマニュアル"

      expect(page).to have_current_path(help_guide_path(:judge))
    end

    it "navigates to admin guide when clicking the card" do
      visit help_path

      click_link "管理者向けマニュアル"

      expect(page).to have_current_path(help_guide_path(:admin))
    end
  end

  describe "help show page" do
    it "displays guide content with table of contents" do
      visit help_guide_path(:participant)

      expect(page).to have_content("目次")
      expect(page).to have_content("マニュアル一覧に戻る")
    end

    it "navigates back to guide list" do
      visit help_guide_path(:participant)

      click_link "マニュアル一覧に戻る", match: :first

      expect(page).to have_current_path(help_path)
    end

    it "displays markdown content properly rendered" do
      visit help_guide_path(:participant)

      # Should have rendered headings from markdown
      expect(page).to have_css("h1, h2, h3")
    end
  end

  describe "navigation to help from header" do
    let!(:terms) { create(:terms_of_service, :current) }
    let!(:user) { create(:user, :confirmed, tutorial_settings: { "show_tutorials" => false }) }

    before do
      create(:terms_acceptance, user: user, terms_of_service: terms)
    end

    it "shows help link when logged in" do
      login_as user, scope: :user
      visit root_path

      # Resize to desktop size
      page.driver.browser.manage.window.resize_to(1280, 800)

      within("header") do
        expect(page).to have_link("ヘルプ")
      end
    end

    it "navigates to help page from header" do
      login_as user, scope: :user
      visit root_path

      # Resize to desktop size
      page.driver.browser.manage.window.resize_to(1280, 800)

      within("header") do
        first(:link, I18n.t("help.navigation.help")).click
      end

      expect(page).to have_current_path(help_path)
    end
  end

  describe "navigation to help from footer" do
    it "shows help link in footer" do
      visit root_path

      within("footer") do
        expect(page).to have_link("利用ガイド")
      end
    end

    it "navigates to help page from footer" do
      visit root_path

      within("footer") do
        click_link "利用ガイド"
      end

      expect(page).to have_current_path(help_path)
    end
  end

  describe "mobile table of contents toggle", js: true do
    before do
      # Set mobile viewport
      page.driver.browser.manage.window.resize_to(375, 667)
    end

    it "toggles table of contents on mobile" do
      visit help_guide_path(:participant)

      # TOC content should be hidden on mobile by default
      toc_button = find("button", text: "目次")
      expect(toc_button).to be_visible

      # Click to expand
      toc_button.click

      # TOC content should now be visible
      expect(page).to have_css("[data-toc-target='content']:not(.hidden)", wait: 2)
    end
  end
end
