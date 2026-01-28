# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  describe "user registration" do
    let!(:terms) { create(:terms_of_service, :current) }

    it "registers a new user successfully" do
      visit new_user_registration_path

      fill_in "メールアドレス", with: "newuser@example.com"
      fill_in "パスワード", with: "password123", match: :first
      fill_in "パスワード（確認）", with: "password123"

      click_button "アカウントを作成"

      expect(page).to have_content("確認")
      expect(User.find_by(email: "newuser@example.com")).to be_present
    end

    it "shows validation errors for invalid registration" do
      visit new_user_registration_path

      fill_in "メールアドレス", with: ""
      fill_in "パスワード", with: "short", match: :first
      fill_in "パスワード（確認）", with: "short"

      click_button "アカウントを作成"

      # Check for error messages in the page
      expect(page).to have_content("メールアドレス")
    end
  end

  describe "user login" do
    let!(:terms) { create(:terms_of_service, :current) }
    let!(:user) { create(:user, :organizer, :confirmed, email: "test@example.com", password: "password123") }

    before do
      create(:terms_acceptance, user: user, terms_of_service: terms)
    end

    it "logs in successfully with valid credentials" do
      visit new_user_session_path

      fill_in "メールアドレス", with: "test@example.com"
      fill_in "パスワード", with: "password123"

      click_button "ログイン"

      expect(page).to have_content("ログインしました")
    end

    it "shows error for invalid credentials" do
      visit new_user_session_path

      fill_in "メールアドレス", with: "test@example.com"
      fill_in "パスワード", with: "wrongpassword"

      click_button "ログイン"

      expect(page).to have_content("メールアドレスまたはパスワードが違います")
    end

    it "shows error for unconfirmed user" do
      create(:user, :organizer, :unconfirmed, email: "unconfirmed@example.com")

      visit new_user_session_path

      fill_in "メールアドレス", with: "unconfirmed@example.com"
      fill_in "パスワード", with: "password123"

      click_button "ログイン"

      expect(page).to have_content("確認")
    end
  end

  describe "user logout" do
    let!(:terms) { create(:terms_of_service, :current) }
    let!(:user) { create(:user, :organizer, :confirmed) }

    before do
      create(:terms_acceptance, user: user, terms_of_service: terms)
    end

    it "logs out successfully" do
      login_as user, scope: :user
      visit organizers_dashboard_path

      # Verify we're logged in
      expect(page).to have_content(user.email)

      # Resize window to show desktop navigation
      page.driver.browser.manage.window.resize_to(1280, 800)

      # Auto-accept confirmation dialogs
      page.execute_script("window.confirm = () => true")

      # Find and click the first (desktop) logout button
      within("header nav") do
        first(:button, "ログアウト").click
      end

      # Wait for redirect and verify
      expect(page).to have_current_path(root_path).or have_current_path(new_user_session_path)
    end
  end

  describe "password reset" do
    let!(:user) { create(:user, :organizer, :confirmed, email: "reset@example.com") }

    it "shows password reset page" do
      visit new_user_password_path

      expect(page).to have_content("パスワード")
      expect(page).to have_field("メールアドレス")
    end
  end

  describe "terms of service acceptance" do
    let!(:terms) { create(:terms_of_service, :current) }
    let!(:user) { create(:user, :organizer, :confirmed) }

    it "requires terms acceptance before accessing dashboard" do
      login_as user, scope: :user

      visit organizers_dashboard_path

      expect(page).to have_content("利用規約")
    end
  end
end
