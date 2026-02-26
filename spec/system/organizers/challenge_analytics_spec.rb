# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::ChallengeAnalytics", type: :system do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:terms) { create(:terms_of_service, :current) }
  let(:area) { create(:area, user: organizer) }
  let(:contest) { create(:contest, :accepting_entries, user: organizer, area: area) }
  let(:challenge) do
    create(:discovery_challenge, :active, contest: contest,
           name: "Test Challenge", theme: "Nature",
           starts_at: 7.days.ago, ends_at: 7.days.from_now)
  end

  before do
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    driven_by(:selenium_chrome_headless)
  end

  describe "challenge detail page with analytics" do
    before { login_as organizer, scope: :user }

    context "with no entries" do
      it "displays challenge information with zero counts" do
        visit organizers_contest_discovery_challenge_path(contest, challenge)

        expect(page).to have_content("Test Challenge")
        expect(page).to have_content("開催中")
        expect(page).to have_content("テーマ: Nature")

        # Statistics section - look for the specific stats card
        expect(page).to have_content("エントリー数")
        expect(page).to have_content("参加者数")
        expect(page).to have_content("発掘スポット数")
      end

      it "shows empty state for entries section" do
        visit organizers_contest_discovery_challenge_path(contest, challenge)

        expect(page).to have_content("まだエントリーがありません")
      end

      it "shows empty state for discovered spots" do
        visit organizers_contest_discovery_challenge_path(contest, challenge)

        expect(page).to have_content("まだスポットが発掘されていません")
      end
    end

    context "with entries and participants" do
      let(:user1) { create(:user, :confirmed, name: "Top Contributor") }
      let(:user2) { create(:user, :confirmed, name: "Second Contributor") }
      let(:spot1) { create(:spot, :certified, contest: contest, name: "Popular Spot", category: :restaurant) }
      let(:spot2) { create(:spot, :discovered, contest: contest, name: "New Discovery", category: :landmark, discovered_by: user1) }

      before do
        # Create entries linked to the challenge
        3.times do
          entry = create(:entry, contest: contest, user: user1, spot: spot1)
          create(:challenge_entry, discovery_challenge: challenge, entry: entry)
        end

        2.times do
          entry = create(:entry, contest: contest, user: user2, spot: spot2)
          create(:challenge_entry, discovery_challenge: challenge, entry: entry)
        end
      end

      it "displays correct entry count" do
        visit organizers_contest_discovery_challenge_path(contest, challenge)

        within("[data-testid='stats-section']") do
          expect(page).to have_content("エントリー数")
          expect(page).to have_content("5")
        end
      end

      it "displays correct participant count" do
        visit organizers_contest_discovery_challenge_path(contest, challenge)

        within("[data-testid='stats-section']") do
          expect(page).to have_content("参加者数")
          expect(page).to have_content("2")
        end
      end

      it "displays entries thumbnails" do
        visit organizers_contest_discovery_challenge_path(contest, challenge)

        within("[data-testid='entries-section']") do
          expect(page).to have_selector(".grid img", minimum: 5)
        end
      end

      it "displays discovered spots list" do
        visit organizers_contest_discovery_challenge_path(contest, challenge)

        within("[data-testid='spots-section']") do
          expect(page).to have_content("Popular Spot")
          expect(page).to have_content("New Discovery")
        end
      end
    end

    context "with different challenge statuses" do
      it "displays draft status badge" do
        draft_challenge = create(:discovery_challenge, :draft, contest: contest, name: "Draft Challenge")
        visit organizers_contest_discovery_challenge_path(contest, draft_challenge)

        expect(page).to have_content("下書き")
      end

      it "displays active status badge" do
        visit organizers_contest_discovery_challenge_path(contest, challenge)

        expect(page).to have_content("開催中")
      end

      it "displays finished status badge" do
        finished_challenge = create(:discovery_challenge, :finished, contest: contest, name: "Finished Challenge")
        visit organizers_contest_discovery_challenge_path(contest, finished_challenge)

        expect(page).to have_content("終了")
      end
    end

    context "navigation" do
      it "navigates back to challenge list" do
        visit organizers_contest_discovery_challenge_path(contest, challenge)

        click_link "チャレンジ一覧に戻る"

        expect(page).to have_current_path(organizers_contest_discovery_challenges_path(contest))
      end

      it "navigates to edit page" do
        visit organizers_contest_discovery_challenge_path(contest, challenge)

        click_link "編集"

        expect(page).to have_current_path(edit_organizers_contest_discovery_challenge_path(contest, challenge))
      end
    end
  end

  describe "challenge comparison" do
    let!(:challenge1) do
      create(:discovery_challenge, :finished, contest: contest,
             name: "Challenge 1", starts_at: 14.days.ago, ends_at: 7.days.ago)
    end
    let!(:challenge2) do
      create(:discovery_challenge, :active, contest: contest,
             name: "Challenge 2", starts_at: 7.days.ago, ends_at: 7.days.from_now)
    end

    before do
      # Challenge 1: 5 entries
      user = create(:user, :confirmed)
      5.times do
        entry = create(:entry, contest: contest, user: user)
        create(:challenge_entry, discovery_challenge: challenge1, entry: entry)
      end

      # Challenge 2: 3 entries
      3.times do
        entry = create(:entry, contest: contest, user: user)
        create(:challenge_entry, discovery_challenge: challenge2, entry: entry)
      end

      login_as organizer, scope: :user
    end

    it "shows challenges in the list with their entry counts" do
      visit organizers_contest_discovery_challenges_path(contest)

      expect(page).to have_content("Challenge 1")
      expect(page).to have_content("Challenge 2")
    end
  end
end
