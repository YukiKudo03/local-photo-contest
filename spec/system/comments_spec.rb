# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Comments", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  let!(:terms) { create(:terms_of_service, :current) }
  let!(:organizer) { create(:user, :organizer, :confirmed) }
  let!(:participant) { create(:user, :confirmed, name: "テストユーザー") }
  let!(:other_participant) { create(:user, :confirmed, name: "他のユーザー") }
  let!(:contest) { create(:contest, :published, user: organizer) }
  let!(:entry) { create(:entry, user: other_participant, contest: contest) }

  before do
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    create(:terms_acceptance, user: participant, terms_of_service: terms)
    create(:terms_acceptance, user: other_participant, terms_of_service: terms)

    # Approve entry for visibility
    entry.update!(moderation_status: :moderation_approved)
  end

  describe "posting comments" do
    context "when logged in" do
      before do
        login_as participant, scope: :user
      end

      it "allows posting a comment" do
        visit entry_path(entry)

        fill_in "comment_body", with: "素晴らしい写真ですね！"
        click_button "コメントする"

        expect(page).to have_content("素晴らしい写真ですね！")
        expect(page).to have_content("テストユーザー")
      end

      it "shows validation error for empty comment" do
        visit entry_path(entry)

        click_button "コメントする"

        expect(page).to have_content("を入力してください")
      end
    end

    context "when not logged in" do
      it "prompts user to login" do
        visit entry_path(entry)

        expect(page).to have_content("コメントするには")
        expect(page).to have_link("ログイン")
      end
    end
  end

  describe "deleting comments" do
    context "when deleting own comment" do
      let!(:comment) { create(:comment, user: participant, entry: entry, body: "私のコメント") }

      before do
        login_as participant, scope: :user
      end

      it "shows delete button for own comment" do
        visit entry_path(entry)

        expect(page).to have_content("私のコメント")
        expect(page).to have_button("削除")
      end

      it "deletes comment when confirmed", js: true do
        visit entry_path(entry)

        expect(page).to have_content("私のコメント")

        # Auto-accept the confirm dialog
        page.execute_script("window.confirm = () => true")
        click_button "削除"

        expect(page).not_to have_content("私のコメント")
      end
    end

    context "when viewing other's comment" do
      let!(:comment) { create(:comment, user: other_participant, entry: entry, body: "他の人のコメント") }

      before do
        login_as participant, scope: :user
      end

      it "does not show delete button for other's comment" do
        visit entry_path(entry)

        expect(page).to have_content("他の人のコメント")

        # Should not see delete button for other user's comment
        within("#comment_#{comment.id}") do
          expect(page).not_to have_button("削除")
        end
      end
    end
  end

  describe "comment list" do
    before do
      create(:comment, user: participant, entry: entry, body: "コメント1", created_at: 1.hour.ago)
      create(:comment, user: other_participant, entry: entry, body: "コメント2", created_at: 30.minutes.ago)
      create(:comment, user: participant, entry: entry, body: "コメント3", created_at: 10.minutes.ago)
    end

    it "displays all comments" do
      visit entry_path(entry)

      expect(page).to have_content("コメント1")
      expect(page).to have_content("コメント2")
      expect(page).to have_content("コメント3")
    end

    it "shows comment count" do
      visit entry_path(entry)

      expect(page).to have_content("3")
    end
  end
end
