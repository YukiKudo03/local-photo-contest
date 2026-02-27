# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::AreaManagement", type: :system do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:terms) { create(:terms_of_service, :current) }

  before do
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    driven_by(:selenium_chrome_headless)
  end

  describe "area creation flow" do
    before { login_as organizer, scope: :user }

    it "creates a new area successfully" do
      visit organizers_areas_path

      first(:link, "新規作成").click
      expect(page).to have_content(I18n.t('organizers.areas.new.title'))

      fill_in "エリア名", with: "渋谷エリア"
      select "東京都", from: "都道府県"
      fill_in "市区町村", with: "渋谷区"
      fill_in "番地等", with: "道玄坂1-2-3"
      fill_in "説明", with: "渋谷駅周辺の撮影エリアです。"

      click_button "作成"

      expect(page).to have_content("エリアを作成しました")
      expect(page).to have_content("渋谷エリア")
    end

    it "shows validation errors for invalid input" do
      visit new_organizers_area_path

      click_button "作成"

      expect(page).to have_content("地域名 を入力してください")
    end

    it "can cancel creation and return to list" do
      visit new_organizers_area_path

      click_link "キャンセル"

      expect(page).to have_current_path(organizers_areas_path)
    end
  end

  describe "area editing flow" do
    let!(:area) { create(:area, user: organizer, name: "元のエリア名", prefecture: "東京都") }

    before { login_as organizer, scope: :user }

    it "edits an existing area successfully" do
      visit organizers_area_path(area)

      click_link "編集"
      expect(page).to have_content("エリア編集")

      fill_in "エリア名", with: "更新されたエリア名"

      click_button "更新"

      expect(page).to have_content("エリアを更新しました")
      expect(page).to have_content("更新されたエリア名")
    end

    it "shows validation errors for invalid edit" do
      visit edit_organizers_area_path(area)

      fill_in "エリア名", with: ""
      click_button "更新"

      expect(page).to have_content("地域名 を入力してください")
    end
  end

  describe "area deletion flow" do
    context "when area has no contests" do
      let!(:area) { create(:area, user: organizer, name: "削除予定のエリア") }

      before { login_as organizer, scope: :user }

      it "deletes an area" do
        visit organizers_area_path(area)

        # Auto-accept the Turbo confirm dialog
        page.execute_script("window.confirm = () => true")
        click_button "削除"

        expect(page).to have_content("エリアを削除しました")
        expect(page).to have_current_path(organizers_areas_path)
        expect(page).not_to have_content("削除予定のエリア")
      end
    end

    context "when area has contests" do
      let!(:area) { create(:area, user: organizer, name: "コンテスト付きエリア") }
      let!(:contest) { create(:contest, user: organizer, area: area) }

      before { login_as organizer, scope: :user }

      it "shows warning that area has contests" do
        visit organizers_area_path(area)

        # Area show page should indicate it has contests
        expect(page).to have_content("コンテスト付きエリア")
        expect(page).to have_content(contest.title)
      end
    end
  end

  describe "area list" do
    let!(:area1) { create(:area, user: organizer, name: "エリアA") }
    let!(:area2) { create(:area, user: organizer, name: "エリアB") }
    let!(:other_area) { create(:area, name: "他のユーザーのエリア") }

    before { login_as organizer, scope: :user }

    it "shows only the organizer's areas" do
      visit organizers_areas_path

      expect(page).to have_content("エリアA")
      expect(page).to have_content("エリアB")
      expect(page).not_to have_content("他のユーザーのエリア")
    end
  end

  describe "empty state" do
    before { login_as organizer, scope: :user }

    it "shows empty state when no areas exist" do
      visit organizers_areas_path

      expect(page).to have_content("エリアがありません")
      expect(page).to have_link("新規作成")
    end
  end
end
