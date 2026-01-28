# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Notifications", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  let!(:terms) { create(:terms_of_service, :current) }
  let!(:user) { create(:user, :confirmed) }

  before(:each) do
    create(:terms_acceptance, user: user, terms_of_service: terms)
  end

  describe "notification list" do
    context "when user has notifications" do
      before do
        create(:notification, user: user, title: "新しい通知1", body: "テストメッセージ1", read_at: nil)
        create(:notification, user: user, title: "新しい通知2", body: "テストメッセージ2", read_at: nil)
        create(:notification, user: user, title: "既読通知", body: "既読メッセージ", read_at: 1.hour.ago)
        login_as user, scope: :user
      end

      it "displays all notifications" do
        visit my_notifications_path

        expect(page).to have_content("新しい通知1")
        expect(page).to have_content("新しい通知2")
        expect(page).to have_content("既読通知")
      end

      it "shows unread notification count" do
        visit my_notifications_path

        # The unread count should be visible somewhere
        expect(user.notifications.unread.count).to eq(2)
      end
    end

    context "when user has no notifications" do
      before do
        login_as user, scope: :user
      end

      it "shows empty state" do
        visit my_notifications_path

        expect(page).to have_content("通知がありません")
      end
    end
  end

  describe "marking notifications as read" do
    let!(:notification) { create(:notification, user: user, title: "未読通知", read_at: nil) }

    before do
      login_as user, scope: :user
    end

    it "marks notification as read when viewing" do
      visit my_notification_path(notification)

      notification.reload
      expect(notification.read_at).not_to be_nil
    end
  end

  describe "mark all as read" do
    before do
      create_list(:notification, 3, user: user, read_at: nil)
      login_as user, scope: :user
    end

    it "marks all notifications as read" do
      visit my_notifications_path

      expect(page).to have_button("すべて既読にする")
      click_button "すべて既読にする"

      # Wait for the flash message indicating success
      expect(page).to have_content("すべての通知を既読にしました")

      # Reload user and verify
      user.reload
      expect(user.notifications.unread.count).to eq(0)
    end
  end

  describe "notification navigation" do
    let!(:organizer) { create(:user, :organizer, :confirmed) }
    let!(:contest) { create(:contest, :published, user: organizer) }
    let!(:entry) { create(:entry, user: user, contest: contest) }
    let!(:notification) do
      create(:notification,
             user: user,
             notifiable: entry,
             notification_type: "entry_ranked",
             title: "作品通知",
             body: "あなたの作品に関する通知")
    end

    before do
      create(:terms_acceptance, user: organizer, terms_of_service: terms)
      entry.update!(moderation_status: :moderation_approved)
      login_as user, scope: :user
    end

    it "navigates to linked page when clicking notification" do
      visit my_notification_path(notification)

      expect(page).to have_content("作品通知")
      expect(page).to have_link("リンク先を開く")
    end
  end
end
