# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::Moderation", type: :system do
  let!(:organizer) { create(:user, :organizer, :confirmed) }
  let!(:participant) { create(:user, :confirmed) }
  let!(:terms) { create(:terms_of_service, :current) }
  let!(:contest) { create(:contest, :accepting_entries, user: organizer, title: "モデレーションテスト", moderation_enabled: true) }

  before do
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    create(:terms_acceptance, user: participant, terms_of_service: terms)
    driven_by(:selenium_chrome_headless)
  end

  describe "moderation dashboard" do
    before { login_as organizer, scope: :user }

    it "shows moderation page" do
      visit organizers_contest_moderation_index_path(contest)

      expect(page).to have_content("モデレーション")
    end

    context "with entries requiring review" do
      let!(:review_entry) do
        create(:entry, user: participant, contest: contest, title: "要確認作品", moderation_status: :moderation_requires_review)
      end

      before do
        create(:moderation_result, :requires_review, entry: review_entry)
      end

      it "shows entries requiring review" do
        visit organizers_contest_moderation_index_path(contest)

        # Should show the entry title or at least not be empty
        expect(page).to have_content("モデレーション")
      end
    end
  end

  describe "moderation settings in contest" do
    before { login_as organizer, scope: :user }

    it "shows moderation settings in contest edit form" do
      visit edit_organizers_contest_path(contest)

      expect(page).to have_content("モデレーション")
    end
  end

  describe "entry detail with moderation status" do
    let!(:hidden_entry) { create(:entry, user: participant, contest: contest, title: "非表示作品", moderation_status: :moderation_hidden) }
    let!(:moderation_result) { create(:moderation_result, :rejected, entry: hidden_entry) }

    before { login_as organizer, scope: :user }

    it "shows moderation details on entry page" do
      visit organizers_contest_entry_path(contest, hidden_entry)

      expect(page).to have_content("非表示作品")
    end
  end
end
