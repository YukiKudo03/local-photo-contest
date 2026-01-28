# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Votes", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  let!(:terms) { create(:terms_of_service, :current) }
  let!(:organizer) { create(:user, :organizer, :confirmed) }
  let!(:participant) { create(:user, :confirmed) }
  let!(:other_participant) { create(:user, :confirmed) }
  let!(:contest) { create(:contest, :published, user: organizer) }
  let!(:entry) { create(:entry, user: other_participant, contest: contest) }

  before do
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    create(:terms_acceptance, user: participant, terms_of_service: terms)
    create(:terms_acceptance, user: other_participant, terms_of_service: terms)

    # Approve entry for visibility
    entry.update!(moderation_status: :moderation_approved)
  end

  describe "voting on entries" do
    context "when logged in" do
      before do
        login_as participant, scope: :user
      end

      it "allows adding a vote to an entry" do
        visit entry_path(entry)

        expect(page).to have_content("まだ投票がありません")

        click_button "投票する"

        # Wait for Turbo to update the button
        expect(page).to have_button("投票済み")

        # Reload to verify the vote was saved
        visit entry_path(entry)
        expect(page).to have_content("1票の投票")
      end

      it "allows removing a vote from an entry" do
        create(:vote, user: participant, entry: entry)

        visit entry_path(entry)

        expect(page).to have_content("1票の投票")
        expect(page).to have_button("投票済み")

        click_button "投票済み"

        # Wait for Turbo to update the button
        expect(page).to have_button("投票する")

        # Reload to verify the vote was removed
        visit entry_path(entry)
        expect(page).to have_content("まだ投票がありません")
      end
    end

    context "when voting on own entry" do
      before do
        login_as other_participant, scope: :user
      end

      it "does not show vote button for own entry" do
        visit entry_path(entry)

        expect(page).not_to have_button("投票する")
      end
    end

    context "when contest is finished" do
      before do
        contest.update!(status: :finished)
        login_as participant, scope: :user
      end

      it "does not allow voting after contest ends" do
        visit entry_path(entry)

        # Vote button should be disabled or not present
        expect(page).not_to have_button("投票する")
      end
    end

    context "when not logged in" do
      it "prompts user to login to vote" do
        visit entry_path(entry)

        # Should show login prompt instead of vote button
        expect(page).to have_link("ログイン")
      end
    end
  end

  describe "vote count display" do
    before do
      login_as participant, scope: :user
    end

    it "displays correct vote count" do
      create_list(:vote, 5, entry: entry)

      visit entry_path(entry)

      expect(page).to have_content("5票の投票")
    end

    it "updates vote count after voting" do
      create_list(:vote, 3, entry: entry)

      visit entry_path(entry)

      expect(page).to have_content("3票の投票")

      click_button "投票する"

      # Wait for Turbo to update the button
      expect(page).to have_button("投票済み")

      # Reload to verify the vote count increased
      visit entry_path(entry)
      expect(page).to have_content("4票の投票")
    end
  end

  describe "votes in gallery" do
    before do
      login_as participant, scope: :user
      create_list(:vote, 10, entry: entry)
    end

    it "shows vote count in gallery view" do
      visit gallery_index_path

      expect(page).to have_content("10")
    end
  end
end
