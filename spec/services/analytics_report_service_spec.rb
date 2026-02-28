# frozen_string_literal: true

require "rails_helper"

RSpec.describe AnalyticsReportService, type: :service do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }
  let(:service) { described_class.new(contest) }

  describe "#generate_pdf" do
    it "returns PDF binary starting with %PDF" do
      pdf = service.generate_pdf
      expect(pdf).to be_a(String)
      expect(pdf[0..3]).to eq("%PDF")
    end

    it "generates PDF with entry and vote data" do
      user = create(:user, :confirmed)
      entry = create(:entry, contest: contest, user: user)
      create(:vote, entry: entry, user: create(:user, :confirmed))

      pdf = service.generate_pdf
      expect(pdf[0..3]).to eq("%PDF")
      expect(pdf.length).to be > 100
    end
  end

  describe "#generate_and_attach!" do
    it "attaches PDF to contest via Active Storage" do
      service.generate_and_attach!
      expect(contest.analytics_report_pdf).to be_attached
    end

    it "replaces existing attachment on regeneration" do
      service.generate_and_attach!
      first_blob_id = contest.analytics_report_pdf.blob.id

      service.generate_and_attach!
      contest.reload
      expect(contest.analytics_report_pdf).to be_attached
      expect(contest.analytics_report_pdf.blob.id).not_to eq(first_blob_id)
    end
  end
end
