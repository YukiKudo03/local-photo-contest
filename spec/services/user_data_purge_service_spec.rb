# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserDataPurgeService, type: :service do
  let(:user) { create(:user, :confirmed, name: "Test User", bio: "Test bio") }

  describe "#purge! with mode: :delete" do
    let(:service) { described_class.new(user, mode: :delete) }

    it "destroys the user record" do
      service.purge!
      expect(User.find_by(id: user.id)).to be_nil
    end

    it "destroys associated entries" do
      organizer = create(:user, :organizer, :confirmed)
      contest = create(:contest, :published, user: organizer)
      create(:entry, user: user, contest: contest)
      expect { service.purge! }.to change(Entry, :count).by(-1)
    end

    it "destroys associated comments" do
      organizer = create(:user, :organizer, :confirmed)
      contest = create(:contest, :published, user: organizer)
      entry = create(:entry, user: organizer, contest: contest)
      create(:comment, user: user, entry: entry)
      expect { service.purge! }.to change(Comment, :count).by(-1)
    end

    it "destroys associated votes" do
      organizer = create(:user, :organizer, :confirmed)
      contest = create(:contest, :published, user: organizer)
      entry = create(:entry, user: organizer, contest: contest)
      create(:vote, user: user, entry: entry)
      expect { service.purge! }.to change(Vote, :count).by(-1)
    end

    it "logs the purge event" do
      expect(Rails.logger).to receive(:info).with(/Account data purged.*mode=delete/)
      service.purge!
    end

    it "nullifies spots discovered_by_id" do
      organizer = create(:user, :organizer, :confirmed)
      contest = create(:contest, :published, user: organizer)
      spot = create(:spot, contest: contest, discovered_by: user)
      service.purge!
      expect(spot.reload.discovered_by_id).to be_nil
    end
  end

  describe "#purge! with mode: :anonymize" do
    let(:service) { described_class.new(user, mode: :anonymize) }

    it "anonymizes the email" do
      service.purge!
      user.reload
      expect(user.email).to match(/deleted_\d+@deleted\.example\.com/)
    end

    it "clears the name and bio" do
      service.purge!
      user.reload
      expect(user.name).to eq("Deleted User")
      expect(user.bio).to be_nil
    end

    it "destroys comments" do
      organizer = create(:user, :organizer, :confirmed)
      contest = create(:contest, :published, user: organizer)
      entry = create(:entry, user: organizer, contest: contest)
      create(:comment, user: user, entry: entry)
      expect { service.purge! }.to change(Comment, :count).by(-1)
    end

    it "destroys notifications" do
      create(:notification, user: user)
      expect { service.purge! }.to change(Notification, :count).by(-1)
    end

    it "preserves the user record" do
      service.purge!
      expect(User.find_by(id: user.id)).to be_present
    end

    it "logs the anonymization in AuditLog" do
      expect { service.purge! }.to change(AuditLog, :count).by(1)
      log = AuditLog.last
      expect(log.action).to eq("account_data_purged")
    end
  end
end
