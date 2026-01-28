# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationBroadcaster, type: :service do
  let!(:terms) { create(:terms_of_service, :current) }
  let!(:organizer) { create(:user, :organizer, :confirmed) }
  let!(:participant) { create(:user, :confirmed) }
  let!(:contest) { create(:contest, :accepting_entries, user: organizer) }
  let!(:entry) { create(:entry, user: participant, contest: contest) }

  before do
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    create(:terms_acceptance, user: participant, terms_of_service: terms)
  end

  describe ".notify_user" do
    it "broadcasts to the user's notification channel" do
      expect(NotificationsChannel).to receive(:broadcast_to).with(
        organizer,
        hash_including(
          title: "Test Title",
          message: "Test Message",
          type: "info"
        )
      )

      NotificationBroadcaster.notify_user(
        organizer,
        title: "Test Title",
        message: "Test Message"
      )
    end
  end

  describe ".new_entry" do
    it "broadcasts new entry notification to organizer" do
      expect(NotificationsChannel).to receive(:broadcast_to).with(
        organizer,
        hash_including(
          title: "新規応募",
          type: "entry"
        )
      )

      NotificationBroadcaster.new_entry(entry)
    end
  end

  describe ".vote_update" do
    it "broadcasts vote count update to entry channel" do
      expect(EntryChannel).to receive(:broadcast_to).with(
        entry,
        hash_including(
          type: "vote_update",
          entry_id: entry.id
        )
      )

      NotificationBroadcaster.vote_update(entry)
    end
  end

  describe ".moderation_result" do
    before do
      entry.update!(moderation_status: :moderation_approved)
    end

    it "broadcasts moderation result to entry owner" do
      expect(NotificationsChannel).to receive(:broadcast_to).with(
        participant,
        hash_including(
          title: "作品審査結果",
          type: "success"
        )
      )

      NotificationBroadcaster.moderation_result(entry)
    end
  end

  describe ".contest_status_change" do
    it "broadcasts contest status change to participants" do
      expect(NotificationsChannel).to receive(:broadcast_to).with(
        participant,
        hash_including(
          title: "コンテスト更新"
        )
      )

      NotificationBroadcaster.contest_status_change(contest, :finished)
    end
  end
end
