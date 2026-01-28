# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::SpotManagement", type: :system do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:terms) { create(:terms_of_service, :current) }
  let(:area) { create(:area, user: organizer) }
  let(:contest) { create(:contest, :draft, user: organizer, area: area) }

  before do
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    driven_by(:selenium_chrome_headless)
  end

  describe "spot creation flow" do
    before { login_as organizer, scope: :user }

    it "creates a new spot successfully" do
      visit organizers_contest_spots_path(contest)

      # Click the first "スポット追加" link (in the header)
      first(:link, "スポット追加").click
      expect(page).to have_content("スポット追加")
      expect(page).to have_content("新しいスポットを登録します")

      fill_in "スポット名", with: "渋谷カフェ"
      select "飲食店", from: "カテゴリ"
      fill_in "住所", with: "渋谷区道玄坂1-2-3"
      fill_in "説明", with: "おしゃれなカフェです。"

      click_button "登録する"

      expect(page).to have_content("渋谷カフェ")
      expect(page).to have_content("飲食店")
    end

    it "shows validation errors for invalid input" do
      visit new_organizers_contest_spot_path(contest)

      click_button "登録する"

      expect(page).to have_content("Name を入力してください")
    end

    it "can cancel creation and return to list" do
      visit new_organizers_contest_spot_path(contest)

      click_link "キャンセル"

      expect(page).to have_current_path(organizers_contest_spots_path(contest))
    end
  end

  describe "spot editing flow" do
    let!(:spot) { create(:spot, contest: contest, name: "元のスポット名", category: :restaurant) }

    before { login_as organizer, scope: :user }

    it "edits an existing spot successfully" do
      visit organizers_contest_spots_path(contest)

      # Click the edit icon link (first one in the row)
      within("tr", text: "元のスポット名") do
        find('a[href*="edit"]').click
      end

      expect(page).to have_content("スポット編集")

      fill_in "スポット名", with: "更新されたスポット名"
      select "公園・広場", from: "カテゴリ"

      click_button "更新する"

      # Check that the spot was updated (flash may not be visible due to Turbo)
      expect(page).to have_content("更新されたスポット名")
      expect(page).to have_content("公園・広場")
    end

    it "shows validation errors for invalid edit" do
      visit edit_organizers_contest_spot_path(contest, spot)

      fill_in "スポット名", with: ""
      click_button "更新する"

      expect(page).to have_content("Name を入力してください")
    end
  end

  describe "spot deletion flow" do
    let!(:spot) { create(:spot, contest: contest, name: "削除予定のスポット") }

    before { login_as organizer, scope: :user }

    it "deletes a spot" do
      visit organizers_contest_spots_path(contest)

      # Auto-accept the Turbo confirm dialog
      page.execute_script("window.confirm = () => true")

      within("tr", text: "削除予定のスポット") do
        find("form[action*='spots'] button[type='submit']").click
      end

      expect(page).not_to have_content("削除予定のスポット")
    end
  end

  describe "spot list with categories" do
    let!(:restaurant) { create(:spot, contest: contest, name: "テストレストラン", category: :restaurant) }
    let!(:landmark) { create(:spot, contest: contest, name: "テスト名所", category: :landmark) }
    let!(:park) { create(:spot, contest: contest, name: "テスト公園", category: :park) }

    before { login_as organizer, scope: :user }

    it "shows all spots with their categories" do
      visit organizers_contest_spots_path(contest)

      expect(page).to have_content("テストレストラン")
      expect(page).to have_content("飲食店")
      expect(page).to have_content("テスト名所")
      expect(page).to have_content("名所・ランドマーク")
      expect(page).to have_content("テスト公園")
      expect(page).to have_content("公園・広場")
    end
  end

  describe "empty state" do
    before { login_as organizer, scope: :user }

    it "shows empty state when no spots exist" do
      visit organizers_contest_spots_path(contest)

      expect(page).to have_content("スポットがありません")
    end
  end

  describe "navigation from contest" do
    let!(:spot) { create(:spot, contest: contest, name: "テストスポット") }

    before { login_as organizer, scope: :user }

    it "navigates to spots from contest detail page" do
      visit organizers_contest_path(contest)

      click_link "スポット管理"

      expect(page).to have_current_path(organizers_contest_spots_path(contest))
      expect(page).to have_content("テストスポット")
    end
  end
end
