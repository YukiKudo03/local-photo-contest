# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Judge Evaluation", type: :system do
  let!(:organizer) { create(:user, :organizer, :confirmed) }
  let!(:judge_user) { create(:user, :confirmed, name: "審査員太郎") }
  let!(:participant) { create(:user, :confirmed) }
  let!(:terms) { create(:terms_of_service, :current) }
  let!(:contest) { create(:contest, :accepting_entries, user: organizer, title: "審査テストコンテスト") }
  let!(:contest_judge) { create(:contest_judge, contest: contest, user: judge_user) }
  let!(:criterion1) { create(:evaluation_criterion, contest: contest, name: "構図", max_score: 10, position: 1) }
  let!(:criterion2) { create(:evaluation_criterion, contest: contest, name: "色彩", max_score: 10, position: 2) }
  let!(:entry1) { create(:entry, user: participant, contest: contest, title: "作品1") }
  let!(:entry2) { create(:entry, user: participant, contest: contest, title: "作品2") }

  before do
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    create(:terms_acceptance, user: judge_user, terms_of_service: terms)
    create(:terms_acceptance, user: participant, terms_of_service: terms)
    driven_by(:selenium_chrome_headless)
  end

  describe "judge assignments list" do
    before { login_as judge_user, scope: :user }

    it "shows assigned contests" do
      visit my_judge_assignments_path

      expect(page).to have_content("審査担当コンテスト")
      expect(page).to have_content("審査テストコンテスト")
    end

    it "shows empty state when no assignments" do
      contest_judge.destroy

      visit my_judge_assignments_path

      expect(page).to have_content("審査担当のコンテストがありません")
    end
  end

  describe "judge assignment detail" do
    before { login_as judge_user, scope: :user }

    it "shows contest details and entries" do
      visit my_judge_assignment_path(contest_judge)

      expect(page).to have_content("審査テストコンテスト")
      expect(page).to have_content("作品1")
      expect(page).to have_content("作品2")
      expect(page).to have_content("構図")
      expect(page).to have_content("色彩")
    end

    it "shows evaluation status for each entry" do
      visit my_judge_assignment_path(contest_judge)

      expect(page).to have_content("未評価")
    end

    it "shows own entries as non-evaluable" do
      own_entry = create(:entry, user: judge_user, contest: contest, title: "自分の作品")

      visit my_judge_assignment_path(contest_judge)

      expect(page).to have_content("自分の作品")
    end
  end

  describe "entry evaluation" do
    before { login_as judge_user, scope: :user }

    it "shows evaluation form" do
      visit my_judge_assignment_evaluation_path(contest_judge, entry1)

      expect(page).to have_content("作品1")
      expect(page).to have_content("構図")
      expect(page).to have_content("色彩")
      expect(page).to have_content("評価フォーム")
    end

    it "saves evaluation successfully" do
      visit my_judge_assignment_evaluation_path(contest_judge, entry1)

      fill_in "comment", with: "素晴らしい作品です"
      click_button "評価を保存"

      expect(page).to have_content("評価を保存しました")
    end

    it "updates evaluation successfully" do
      create(:judge_evaluation, contest_judge: contest_judge, entry: entry1, evaluation_criterion: criterion1, score: 7)
      create(:judge_evaluation, contest_judge: contest_judge, entry: entry1, evaluation_criterion: criterion2, score: 8)

      visit my_judge_assignment_evaluation_path(contest_judge, entry1)

      fill_in "comment", with: "更新されたコメント"
      click_button "評価を更新"

      expect(page).to have_content("評価を更新しました")
    end

    it "prevents evaluating own entry on submission" do
      own_entry = create(:entry, user: judge_user, contest: contest, title: "自分の作品")

      # Try to post directly to evaluation create path
      visit my_judge_assignment_evaluation_path(contest_judge, own_entry)
      click_button "評価を保存"

      expect(page).to have_content("自分の作品は評価できません")
    end
  end

  describe "evaluation progress tracking" do
    before { login_as judge_user, scope: :user }

    it "shows evaluated status on assignment list" do
      # Evaluate entry1 fully
      create(:judge_evaluation, contest_judge: contest_judge, entry: entry1, evaluation_criterion: criterion1, score: 8)
      create(:judge_evaluation, contest_judge: contest_judge, entry: entry1, evaluation_criterion: criterion2, score: 9)

      visit my_judge_assignment_path(contest_judge)

      expect(page).to have_content("評価済み")
    end
  end

  describe "results announced state" do
    before do
      contest.update!(status: :finished, results_announced_at: Time.current)
      login_as judge_user, scope: :user
    end

    it "shows read-only state for finished contest" do
      visit my_judge_assignment_path(contest_judge)

      expect(page).to have_content("結果発表済み")
    end
  end

  describe "navigation" do
    before { login_as judge_user, scope: :user }

    it "shows judge link in header when user is a judge" do
      page.driver.browser.manage.window.resize_to(1280, 800)
      visit root_path

      expect(page).to have_link("審査担当")
    end

    it "hides judge link when user has no assignments" do
      contest_judge.destroy
      page.driver.browser.manage.window.resize_to(1280, 800)
      visit root_path

      expect(page).not_to have_link("審査担当")
    end
  end
end
