# frozen_string_literal: true

require "rails_helper"

RSpec.describe CertificateGenerationService, type: :service do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:participant) { create(:user, :confirmed) }
  let(:contest) { create(:contest, :accepting_entries, user: organizer) }

  describe "#generate_for_ranking" do
    let!(:entry) { create(:entry, contest: contest, user: participant) }
    let!(:entry2) { create(:entry, contest: contest) }

    before do
      contest.finish!
      contest.update_column(:results_announced_at, Time.current)
    end

    let!(:ranking) { create(:contest_ranking, :first_place, contest: contest, entry: entry) }

    it "returns PDF binary data" do
      service = described_class.new
      pdf_data = service.generate_for_ranking(ranking)
      expect(pdf_data).to be_present
      expect(pdf_data).to start_with("%PDF")
    end

    it "generates different content for different ranks" do
      ranking2 = create(:contest_ranking, :second_place, contest: contest, entry: entry2)

      service = described_class.new
      pdf1 = service.generate_for_ranking(ranking)
      pdf2 = service.generate_for_ranking(ranking2)

      expect(pdf1).not_to eq(pdf2)
    end
  end

  describe "#generate_and_attach!" do
    let!(:entry) { create(:entry, contest: contest, user: participant) }

    before do
      contest.finish!
      contest.update_column(:results_announced_at, Time.current)
    end

    let!(:ranking) { create(:contest_ranking, :first_place, contest: contest, entry: entry) }

    it "attaches PDF to the ranking via Active Storage" do
      service = described_class.new
      service.generate_and_attach!(ranking)

      expect(ranking.certificate_pdf).to be_attached
      expect(ranking.certificate_generated_at).to be_present
    end

    it "does not regenerate if already generated" do
      ranking.update!(certificate_generated_at: Time.current)
      ranking.certificate_pdf.attach(
        io: StringIO.new("%PDF-1.4 existing"),
        filename: "certificate.pdf",
        content_type: "application/pdf"
      )

      service = described_class.new
      expect { service.generate_and_attach!(ranking) }.not_to change { ranking.reload.certificate_generated_at }
    end
  end

  describe "#generate_all_for_contest" do
    let!(:entry1) { create(:entry, contest: contest, user: participant) }
    let!(:entry2) { create(:entry, contest: contest) }
    let!(:entry3) { create(:entry, contest: contest) }

    before do
      contest.finish!
      contest.update_column(:results_announced_at, Time.current)
    end

    let!(:ranking1) { create(:contest_ranking, :first_place, contest: contest, entry: entry1) }
    let!(:ranking2) { create(:contest_ranking, :second_place, contest: contest, entry: entry2) }
    let!(:ranking_no_prize) do
      create(:contest_ranking, contest: contest, entry: entry3, rank: 4, total_score: 50.0)
    end

    it "generates certificates for prize winners only" do
      service = described_class.new
      service.generate_all_for_contest(contest)

      expect(ranking1.reload.certificate_pdf).to be_attached
      expect(ranking2.reload.certificate_pdf).to be_attached
      expect(ranking_no_prize.reload.certificate_pdf).not_to be_attached
    end

    it "skips already-generated certificates" do
      ranking1.update!(certificate_generated_at: Time.current)
      ranking1.certificate_pdf.attach(
        io: StringIO.new("%PDF-1.4 existing"),
        filename: "certificate.pdf",
        content_type: "application/pdf"
      )

      service = described_class.new
      service.generate_all_for_contest(contest)

      # ranking2 should still get generated
      expect(ranking2.reload.certificate_pdf).to be_attached
    end
  end
end
