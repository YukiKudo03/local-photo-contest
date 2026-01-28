# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers Statistics Dashboard", type: :system do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }

  before do
    driven_by(:selenium_chrome_headless)
  end

  describe "accessing statistics dashboard" do
    context "when logged in as contest owner" do
      before do
        login_as organizer, scope: :user
      end

      it "displays the statistics dashboard" do
        visit organizers_contest_statistics_path(contest)

        expect(page).to have_content("統計ダッシュボード")
        expect(page).to have_content(contest.title)
      end

      it "displays summary cards" do
        visit organizers_contest_statistics_path(contest)

        expect(page).to have_content("総応募数")
        expect(page).to have_content("総投票数")
        expect(page).to have_content("参加ユーザー数")
        expect(page).to have_content("登録スポット数")
      end

      it "shows empty state messages when no data" do
        visit organizers_contest_statistics_path(contest)

        expect(page).to have_content("まだデータがありません")
      end

      context "with entries" do
        let!(:user) { create(:user, :confirmed) }
        let!(:entry) { create(:entry, contest: contest, user: user) }

        it "displays entry count in summary" do
          visit organizers_contest_statistics_path(contest)

          # Check that page shows entry count (summary shows "1" in total entries)
          expect(page).to have_content("総応募数")
          expect(page).to have_selector(".text-2xl.font-bold", text: "1")
        end
      end

      context "with spots and entries" do
        let!(:spot) { create(:spot, contest: contest, name: "Test Spot") }
        let!(:user) { create(:user, :confirmed) }
        let!(:entry) { create(:entry, contest: contest, user: user, spot: spot) }

        it "displays spot in rankings" do
          visit organizers_contest_statistics_path(contest)

          expect(page).to have_content("Test Spot")
          expect(page).to have_content("1 件")
        end
      end

      context "with votes" do
        let!(:user1) { create(:user, :confirmed) }
        let!(:user2) { create(:user, :confirmed) }
        let!(:entry) { create(:entry, contest: contest, user: user1, title: "Popular Photo") }
        let!(:vote) { create(:vote, entry: entry, user: user2) }

        it "displays vote analysis section" do
          visit organizers_contest_statistics_path(contest)

          expect(page).to have_content("投票分析")
          expect(page).to have_content("総投票数")
          expect(page).to have_content("ユニーク投票者数")
        end

        it "displays top voted entries" do
          visit organizers_contest_statistics_path(contest)

          expect(page).to have_content("上位得票作品")
          expect(page).to have_content("Popular Photo")
        end
      end

      it "has link back to contest details" do
        visit organizers_contest_statistics_path(contest)

        expect(page).to have_link("← コンテスト詳細に戻る", href: organizers_contest_path(contest))
      end
    end

    context "when contest is draft" do
      let(:draft_contest) { create(:contest, :draft, user: organizer) }

      before do
        login_as organizer, scope: :user
      end

      it "shows message that voting has not started" do
        visit organizers_contest_statistics_path(draft_contest)

        expect(page).to have_content("投票期間開始後に表示されます")
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        visit organizers_contest_statistics_path(contest)

        expect(page).to have_current_path(new_user_session_path)
      end
    end

    context "when logged in as different organizer" do
      let(:other_organizer) { create(:user, :organizer, :confirmed) }

      before do
        login_as other_organizer, scope: :user
      end

      it "redirects to contests list with error" do
        visit organizers_contest_statistics_path(contest)

        expect(page).to have_current_path(organizers_contests_path)
        expect(page).to have_content("このコンテストにアクセスする権限がありません")
      end
    end
  end
end
