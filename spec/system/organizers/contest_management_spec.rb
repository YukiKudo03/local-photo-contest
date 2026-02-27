# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::ContestManagement", type: :system do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:terms) { create(:terms_of_service, :current) }

  before do
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    driven_by(:selenium_chrome_headless)
  end

  describe "contest creation flow" do
    before { login_as organizer, scope: :user }

    it "creates a new contest successfully" do
      visit organizers_contests_path

      first(:link, "新規作成").click
      expect(page).to have_content("新規コンテスト作成")

      fill_in "タイトル", with: "春の写真コンテスト"
      fill_in "テーマ", with: "桜と春の風景"
      fill_in "説明", with: "春の美しい風景を撮影してください。"

      click_button "作成する"

      expect(page).to have_content("コンテストを作成しました")
      expect(page).to have_content("春の写真コンテスト")
      expect(page).to have_content("桜と春の風景")
      expect(page).to have_content("下書き")
    end

    it "shows validation errors for invalid input" do
      visit new_organizers_contest_path

      click_button "作成する"

      expect(page).to have_content("タイトル を入力してください")
    end

    it "can cancel creation and return to list" do
      visit new_organizers_contest_path

      click_link "キャンセル"

      expect(page).to have_current_path(organizers_contests_path)
    end
  end

  describe "contest editing flow" do
    let!(:contest) { create(:contest, :draft, user: organizer, title: "元のタイトル", theme: "元のテーマ") }

    before { login_as organizer, scope: :user }

    it "edits an existing contest successfully" do
      visit organizers_contest_path(contest)

      click_link "編集"
      expect(page).to have_content("コンテスト編集")

      fill_in "タイトル", with: "更新されたタイトル"
      fill_in "テーマ", with: "更新されたテーマ"

      click_button "更新する"

      expect(page).to have_content("コンテストを更新しました")
      expect(page).to have_content("更新されたタイトル")
      expect(page).to have_content("更新されたテーマ")
    end

    it "shows validation errors for invalid edit" do
      visit edit_organizers_contest_path(contest)

      fill_in "タイトル", with: ""
      click_button "更新する"

      expect(page).to have_content("タイトル を入力してください")
    end
  end

  describe "contest publish flow" do
    let!(:contest) { create(:contest, :draft, user: organizer, title: "公開予定のコンテスト") }

    before { login_as organizer, scope: :user }

    it "publishes a draft contest" do
      visit organizers_contest_path(contest)

      expect(page).to have_content("下書き")

      # Auto-accept the Turbo confirm dialog
      page.execute_script("window.confirm = () => true")
      click_button "公開"

      expect(page).to have_content("コンテストを公開しました")
    end
  end

  describe "contest finish flow" do
    let!(:contest) { create(:contest, :published, user: organizer, title: "終了予定のコンテスト") }

    before { login_as organizer, scope: :user }

    it "finishes a published contest" do
      visit organizers_contest_path(contest)

      expect(page).to have_content("公開中")

      # Auto-accept the Turbo confirm dialog
      page.execute_script("window.confirm = () => true")
      click_button "終了"

      expect(page).to have_content("コンテストを終了しました")
      expect(page).to have_content("終了")
    end
  end

  describe "contest list and filtering" do
    let!(:draft_contest) { create(:contest, :draft, user: organizer, title: "下書きコンテスト") }
    let!(:published_contest) { create(:contest, :published, user: organizer, title: "公開中コンテスト") }
    let!(:finished_contest) { create(:contest, :finished, user: organizer, title: "終了コンテスト") }

    before { login_as organizer, scope: :user }

    it "shows all contests by default" do
      visit organizers_contests_path

      expect(page).to have_content("下書きコンテスト")
      expect(page).to have_content("公開中コンテスト")
      expect(page).to have_content("終了コンテスト")
    end

    it "filters by draft status" do
      visit organizers_contests_path

      click_link "下書き"

      expect(page).to have_content("下書きコンテスト")
      expect(page).not_to have_content("公開中コンテスト")
      expect(page).not_to have_content("終了コンテスト")
    end

    it "filters by published status" do
      visit organizers_contests_path

      click_link "公開中"

      expect(page).not_to have_content("下書きコンテスト")
      expect(page).to have_content("公開中コンテスト")
      expect(page).not_to have_content("終了コンテスト")
    end

    it "filters by finished status" do
      visit organizers_contests_path

      click_link "終了"

      expect(page).not_to have_content("下書きコンテスト")
      expect(page).not_to have_content("公開中コンテスト")
      expect(page).to have_content("終了コンテスト")
    end
  end

  describe "contest deletion flow" do
    context "when contest is draft" do
      let!(:contest) { create(:contest, :draft, user: organizer, title: "削除予定のコンテスト") }

      before { login_as organizer, scope: :user }

      it "deletes a draft contest" do
        visit organizers_contest_path(contest)

        # Auto-accept the Turbo confirm dialog
        page.execute_script("window.confirm = () => true")
        click_button "削除"

        expect(page).to have_content("コンテストを削除しました")
        expect(page).to have_current_path(organizers_contests_path)
        expect(page).not_to have_content("削除予定のコンテスト")
      end
    end

    context "when contest is published" do
      let!(:contest) { create(:contest, :published, user: organizer, title: "公開中のコンテスト") }

      before { login_as organizer, scope: :user }

      it "does not show delete button for published contest" do
        visit organizers_contest_path(contest)

        expect(page).not_to have_button("削除")
      end
    end
  end

  describe "empty state" do
    before { login_as organizer, scope: :user }

    it "shows empty state when no contests exist" do
      visit organizers_contests_path

      expect(page).to have_content("コンテストがありません")
      expect(page).to have_content("最初のコンテストを作成しましょう")
    end
  end
end
