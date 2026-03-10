# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContestRanking, type: :model do
  describe "associations" do
    it { should belong_to(:contest) }
    it { should belong_to(:entry) }
  end

  describe "validations" do
    let(:contest) { create(:contest, :published) }
    let(:entry) { create(:entry, contest: contest) }

    it "validates presence of rank" do
      ranking = build(:contest_ranking, contest: contest, entry: entry, rank: nil)
      expect(ranking).not_to be_valid
    end

    it "validates presence of total_score" do
      ranking = build(:contest_ranking, contest: contest, entry: entry, total_score: nil)
      expect(ranking).not_to be_valid
    end
  end

  describe "certificate attachment" do
    it { should respond_to(:certificate_pdf) }

    it "can attach a certificate PDF" do
      contest = create(:contest, :published)
      entry = create(:entry, contest: contest)
      ranking = create(:contest_ranking, contest: contest, entry: entry)

      ranking.certificate_pdf.attach(
        io: StringIO.new("%PDF-1.4 test"),
        filename: "certificate.pdf",
        content_type: "application/pdf"
      )

      expect(ranking.certificate_pdf).to be_attached
    end
  end

  describe "#prize_label" do
    let(:contest) { create(:contest, :published) }
    let(:entry) { create(:entry, contest: contest) }

    it "returns grand_prize for rank 1" do
      ranking = create(:contest_ranking, contest: contest, entry: entry, rank: 1)
      expect(ranking.prize_label).to eq(I18n.t('ranks.grand_prize'))
    end

    it "returns excellence for rank 2" do
      ranking = create(:contest_ranking, contest: contest, entry: entry, rank: 2)
      expect(ranking.prize_label).to eq(I18n.t('ranks.excellence'))
    end

    it "returns merit for rank 3" do
      ranking = create(:contest_ranking, contest: contest, entry: entry, rank: 3)
      expect(ranking.prize_label).to eq(I18n.t('ranks.merit'))
    end

    it "returns award for rank 4+" do
      ranking = create(:contest_ranking, contest: contest, entry: entry, rank: 4)
      expect(ranking.prize_label).to eq(I18n.t('ranks.award'))
    end
  end

  describe "#certificate_generated?" do
    let(:contest) { create(:contest, :published) }
    let(:entry) { create(:entry, contest: contest) }

    it "returns false when certificate_generated_at is nil" do
      ranking = create(:contest_ranking, contest: contest, entry: entry)
      expect(ranking.certificate_generated?).to be false
    end

    it "returns true when certificate_generated_at is set" do
      ranking = create(:contest_ranking, contest: contest, entry: entry,
                        certificate_generated_at: Time.current)
      expect(ranking.certificate_generated?).to be true
    end
  end

  describe "#winner_notified?" do
    let(:contest) { create(:contest, :published) }
    let(:entry) { create(:entry, contest: contest) }

    it "returns false when winner_notified_at is nil" do
      ranking = create(:contest_ranking, contest: contest, entry: entry)
      expect(ranking.winner_notified?).to be false
    end

    it "returns true when winner_notified_at is set" do
      ranking = create(:contest_ranking, contest: contest, entry: entry,
                        winner_notified_at: Time.current)
      expect(ranking.winner_notified?).to be true
    end
  end
end
