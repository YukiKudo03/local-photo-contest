# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Account Lock", type: :system do
  let!(:terms) { create(:terms_of_service, :current) }
  let!(:user) { create(:user, :organizer, :confirmed, email: "locktest@example.com", password: "password123") }

  before do
    create(:terms_acceptance, user: user, terms_of_service: terms)
    driven_by(:selenium_chrome_headless)
  end

  describe "login attempts" do
    it "allows login with correct password" do
      visit new_user_session_path

      fill_in "メールアドレス", with: "locktest@example.com"
      fill_in "パスワード", with: "password123"
      click_button "ログイン"

      expect(page).to have_content("ログインしました")
    end

    it "shows error for wrong password" do
      visit new_user_session_path

      fill_in "メールアドレス", with: "locktest@example.com"
      fill_in "パスワード", with: "wrongpassword"
      click_button "ログイン"

      expect(page).to have_content("メールアドレスまたはパスワードが違います")
    end

    it "shows locked message when account is locked" do
      # Lock the account by setting locked_at directly
      user.update!(locked_at: Time.current)

      visit new_user_session_path

      fill_in "メールアドレス", with: "locktest@example.com"
      fill_in "パスワード", with: "password123"
      click_button "ログイン"

      expect(page).to have_content("ロック")
    end
  end

  describe "account unlock" do
    before do
      user.update!(locked_at: Time.current)
    end

    it "prevents login while locked" do
      visit new_user_session_path

      fill_in "メールアドレス", with: "locktest@example.com"
      fill_in "パスワード", with: "password123"
      click_button "ログイン"

      expect(page).not_to have_content("ログインしました")
    end

    it "allows login after manual unlock" do
      user.update!(locked_at: nil, failed_attempts: 0)

      visit new_user_session_path

      fill_in "メールアドレス", with: "locktest@example.com"
      fill_in "パスワード", with: "password123"
      click_button "ログイン"

      expect(page).to have_content("ログインしました")
    end
  end

  describe "unlock page" do
    it "shows unlock instructions request page" do
      visit new_user_unlock_path

      expect(page).to have_field("メールアドレス")
    end
  end
end
