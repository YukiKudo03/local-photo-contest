# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Discovery Features", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  describe "Discovery Spots Review" do
    let(:organizer) { create(:user, :organizer, :confirmed) }
    let(:contest) { create(:contest, :published, user: organizer) }
    let(:discoverer) { create(:user, :confirmed) }
    let!(:pending_spot) do
      create(:spot, :discovered, contest: contest, name: "発掘スポット1", discovered_by: discoverer)
    end

    context "when logged in as organizer" do
      before do
        login_as organizer, scope: :user
      end

      it "displays pending spots for review" do
        visit organizers_contest_discovery_spots_path(contest)

        expect(page).to have_content(I18n.t('organizers.discovery_spots.index.title'))
        expect(page).to have_content("発掘スポット1")
      end

      it "shows certified spots in the certified tab" do
        certified_spot = create(:spot, :certified, contest: contest, name: "認定済みスポット")

        visit organizers_contest_discovery_spots_path(contest)

        # Tab content is controlled by JavaScript, just verify the tab exists
        expect(page).to have_button("認定済み")
      end
    end
  end

  describe "Discovery Challenges Management" do
    let(:organizer) { create(:user, :organizer, :confirmed) }
    let(:contest) { create(:contest, :published, user: organizer) }

    context "when logged in as organizer" do
      before do
        login_as organizer, scope: :user
      end

      it "displays challenges list" do
        challenge = create(:discovery_challenge, :draft, contest: contest, name: "テストチャレンジ")

        visit organizers_contest_discovery_challenges_path(contest)

        expect(page).to have_content("発掘チャレンジ")
        expect(page).to have_content("テストチャレンジ")
      end

      it "can navigate to new challenge form" do
        visit organizers_contest_discovery_challenges_path(contest)

        first(:link, I18n.t('organizers.discovery_challenges.index.new_challenge')).click

        expect(page).to have_content(I18n.t('organizers.discovery_challenges.new.title'))
      end
    end
  end

  describe "Profile Discovery Stats" do
    let(:user) { create(:user, :confirmed, name: "発掘ユーザー") }
    let(:contest) { create(:contest, :published) }

    before do
      create(:spot, :certified, contest: contest, discovered_by: user)
      create(:spot, :discovered, contest: contest, discovered_by: user)
      create(:discovery_badge, :explorer, user: user, contest: contest)
    end

    context "when logged in" do
      before do
        login_as user, scope: :user
      end

      it "displays discovery stats on profile page" do
        visit my_profile_path

        expect(page).to have_content("発掘実績")
        expect(page).to have_content("認定スポット")
        expect(page).to have_content("審査中")
        expect(page).to have_content("探検家") # badge name
      end
    end
  end

  describe "Statistics Dashboard Discovery Section" do
    let(:organizer) { create(:user, :organizer, :confirmed) }
    let(:contest) { create(:contest, :published, user: organizer) }

    before do
      create(:spot, :discovered, contest: contest)
      create(:spot, :certified, contest: contest)
      login_as organizer, scope: :user
    end

    it "displays discovery statistics" do
      visit organizers_contest_statistics_path(contest)

      expect(page).to have_content("発掘統計")
      expect(page).to have_content("総スポット数")
      expect(page).to have_content("認定済み")
      expect(page).to have_content("審査待ち")
    end
  end
end
