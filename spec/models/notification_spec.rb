# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notification, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:notifiable) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:notification_type) }
    it { is_expected.to validate_presence_of(:title) }
  end

  describe "scopes" do
    let(:user) { create(:user, :confirmed) }
    let!(:unread_notification) { create(:notification, user: user) }
    let!(:read_notification) { create(:notification, :read, user: user) }

    describe ".unread" do
      it "returns only unread notifications" do
        expect(Notification.unread).to include(unread_notification)
        expect(Notification.unread).not_to include(read_notification)
      end
    end

    describe ".read" do
      it "returns only read notifications" do
        expect(Notification.read).to include(read_notification)
        expect(Notification.read).not_to include(unread_notification)
      end
    end

    describe ".recent" do
      let(:test_user) { create(:user, :confirmed) }

      it "orders by created_at desc" do
        old_notification = create(:notification, user: test_user, created_at: 2.days.ago)
        new_notification = create(:notification, user: test_user, created_at: 1.hour.ago)

        recent = Notification.for_user(test_user).recent.to_a
        expect(recent.first).to eq(new_notification)
        expect(recent.last).to eq(old_notification)
      end
    end

    describe ".for_user" do
      let(:other_user) { create(:user, :confirmed) }
      let!(:other_notification) { create(:notification, user: other_user) }

      it "returns notifications for the specified user" do
        expect(Notification.for_user(user)).to include(unread_notification)
        expect(Notification.for_user(user)).not_to include(other_notification)
      end
    end
  end

  describe "#read?" do
    it "returns true when read_at is present" do
      notification = build(:notification, :read)
      expect(notification.read?).to be true
    end

    it "returns false when read_at is nil" do
      notification = build(:notification)
      expect(notification.read?).to be false
    end
  end

  describe "#unread?" do
    it "returns false when read_at is present" do
      notification = build(:notification, :read)
      expect(notification.unread?).to be false
    end

    it "returns true when read_at is nil" do
      notification = build(:notification)
      expect(notification.unread?).to be true
    end
  end

  describe "#mark_as_read!" do
    let(:notification) { create(:notification) }

    it "sets read_at to current time" do
      expect(notification.read_at).to be_nil
      notification.mark_as_read!
      expect(notification.reload.read_at).not_to be_nil
    end

    it "does not update if already read" do
      notification.update!(read_at: 1.hour.ago)
      original_read_at = notification.read_at
      notification.mark_as_read!
      expect(notification.reload.read_at).to eq(original_read_at)
    end
  end

  describe ".mark_all_as_read!" do
    let(:user) { create(:user, :confirmed) }
    let!(:notification1) { create(:notification, user: user) }
    let!(:notification2) { create(:notification, user: user) }

    it "marks all unread notifications as read" do
      expect(Notification.unread.count).to eq(2)
      Notification.mark_all_as_read!(user)
      expect(Notification.unread.count).to eq(0)
    end
  end

  describe ".create_results_announced!" do
    let(:user) { create(:user, :confirmed) }
    let(:organizer) { create(:user, :organizer, :confirmed) }
    let(:contest) { create(:contest, :finished, user: organizer) }

    it "creates a notification" do
      expect {
        Notification.create_results_announced!(user: user, contest: contest)
      }.to change(Notification, :count).by(1)
    end

    it "sets correct attributes" do
      notification = Notification.create_results_announced!(user: user, contest: contest)
      expect(notification.notification_type).to eq(Notification::TYPES[:results_announced])
      expect(notification.notifiable).to eq(contest)
      expect(notification.title).to include(contest.title)
    end
  end

  describe ".create_entry_ranked!" do
    let(:organizer) { create(:user, :organizer, :confirmed) }
    let(:contest) { create(:contest, :published, user: organizer) }
    let!(:entry) { create(:entry, contest: contest, title: "My Great Photo") }

    before do
      contest.finish!
    end

    it "creates a notification" do
      expect {
        Notification.create_entry_ranked!(user: entry.user, entry: entry, rank: 1)
      }.to change(Notification, :count).by(1)
    end

    it "sets correct attributes for 1st place" do
      notification = Notification.create_entry_ranked!(user: entry.user, entry: entry, rank: 1)
      expect(notification.notification_type).to eq(Notification::TYPES[:entry_ranked])
      expect(notification.notifiable).to eq(entry)
      expect(notification.title).to include("1位")
    end

    it "sets correct attributes for other places" do
      notification = Notification.create_entry_ranked!(user: entry.user, entry: entry, rank: 3)
      expect(notification.title).to include("3位")
    end
  end
end
