# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataExportMailer, type: :mailer do
  let(:user) { create(:user, :confirmed, name: "Test User") }
  let(:export_request) { create(:data_export_request, :completed, user: user) }

  describe "#export_ready" do
    let(:mail) { described_class.export_ready(export_request) }

    it "renders the subject" do
      expect(mail.subject).to include("データエクスポート")
    end

    it "sends to the user's email" do
      expect(mail.to).to eq([user.email])
    end

    it "includes the expires_at information" do
      expect(mail.body.encoded).to include("7")
    end
  end
end
