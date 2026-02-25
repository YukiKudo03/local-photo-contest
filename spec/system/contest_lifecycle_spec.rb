# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Contest Lifecycle", type: :system do
  let!(:organizer) { create(:user, :organizer, :confirmed, email: "organizer@example.com") }
  let!(:terms) { create(:terms_of_service, :current) }

  before do
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    driven_by(:selenium_chrome_headless)
  end

  describe "complete contest workflow" do
    let!(:category) { create(:category, name: "風景写真") }
    let!(:participant) { create(:user, :confirmed, name: "参加者") }
    let!(:judge_user) { create(:user, :confirmed, name: "審査員") }
    let!(:contest) { create(:contest, :accepting_entries, user: organizer) }
    let!(:contest_judge) { create(:contest_judge, contest: contest, user: judge_user) }
    let!(:criterion) { create(:evaluation_criterion, contest: contest, name: "構図", max_score: 10) }

    before do
      create(:terms_acceptance, user: participant, terms_of_service: terms)
      create(:terms_acceptance, user: judge_user, terms_of_service: terms)
    end

    scenario "participants submit entries and judges evaluate them" do
      # Step 1: 参加者が応募
      login_as participant, scope: :user
      visit contest_path(contest)
      expect(page).to have_content(contest.title)

      # Step 2: 審査員が応募作品を確認
      entry = create(:entry, user: participant, contest: contest, title: "テスト作品")

      logout
      login_as judge_user, scope: :user

      visit my_judge_assignment_path(contest_judge)
      expect(page).to have_content("テスト作品")

      # Step 3: 審査員が評価
      visit my_judge_assignment_evaluation_path(contest_judge, entry)
      fill_in "comment", with: "素晴らしい構図です"
      click_button "評価を保存"

      expect(page).to have_content("評価を保存しました")

      # Step 4: 主催者がコンテストを終了
      logout
      login_as organizer, scope: :user

      contest.finish!
      contest.update!(results_announced_at: Time.current)

      # Step 5: 結果ページを確認
      visit contest_results_path(contest)
      expect(page).to have_content("結果")
    end
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

  describe "error cases" do
    let!(:participant) { create(:user, :confirmed, name: "参加者") }

    before do
      create(:terms_acceptance, user: participant, terms_of_service: terms)
    end

    context "when contest is not accepting entries" do
      let!(:finished_contest) { create(:contest, :finished, user: organizer, title: "終了コンテスト") }

      before { login_as participant, scope: :user }

      it "does not show entry button on finished contest" do
        visit contest_path(finished_contest)

        expect(page).not_to have_link("応募する")
      end
    end

    context "when contest is draft" do
      let!(:draft_contest) { create(:contest, :draft, user: organizer, title: "下書きコンテスト") }

      it "prevents non-organizer from viewing draft contest" do
        login_as participant, scope: :user

        # Draft contests are not in the public scope, so they raise RecordNotFound
        expect {
          visit contest_path(draft_contest)
        }.not_to raise_error

        # In test environment, RecordNotFound shows error page
        expect(page).to have_content("RecordNotFound").or have_content("Not Found").or have_content("404")
      end

      it "allows organizer to view draft contest" do
        login_as organizer, scope: :user
        visit organizers_contest_path(draft_contest)

        expect(page).to have_content("下書きコンテスト")
      end
    end

    context "when user is not logged in" do
      let!(:contest) { create(:contest, :accepting_entries, user: organizer) }

      it "redirects to login when trying to submit entry" do
        visit new_contest_entry_path(contest)

        expect(page).to have_content("ログイン")
      end
    end

    context "when user lacks permission" do
      let!(:other_organizer) { create(:user, :organizer, :confirmed) }
      let!(:contest) { create(:contest, :published, user: organizer) }

      before do
        create(:terms_acceptance, user: other_organizer, terms_of_service: terms)
        login_as other_organizer, scope: :user
      end

      it "denies access to other organizer's contest management" do
        visit organizers_contest_path(contest)

        expect(page).to have_content("権限がありません")
      end
    end
  end
end
