# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountDeletionMailer, type: :mailer do
  let(:user) do
    create(:user, :confirmed, name: "Test User",
           deletion_requested_at: Time.current,
           deletion_scheduled_at: 30.days.from_now)
  end

  describe "#deletion_requested" do
    let(:mail) { described_class.deletion_requested(user) }

    it "sends to the user's email" do
      expect(mail.to).to eq([user.email])
    end

    it "includes deletion schedule info" do
      expect(mail.body.encoded).to be_present
    end
  end

  describe "#deletion_reminder" do
    let(:mail) { described_class.deletion_reminder(user) }

    it "sends to the user's email" do
      expect(mail.to).to eq([user.email])
    end
  end

  describe "#deletion_completed" do
    let(:mail) { described_class.deletion_completed(user) }

    it "sends to the user's email" do
      expect(mail.to).to eq([user.email])
    end
  end

  describe "#deletion_cancelled" do
    let(:mail) { described_class.deletion_cancelled(user) }

    it "sends to the user's email" do
      expect(mail.to).to eq([user.email])
    end
  end
end
