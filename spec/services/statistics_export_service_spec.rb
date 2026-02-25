# frozen_string_literal: true

require "rails_helper"

RSpec.describe StatisticsExportService do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }
  let(:service) { described_class.new(contest) }

  describe "#to_csv" do
    context "when contest has no data" do
      it "returns CSV with headers" do
        csv = service.to_csv

        expect(csv).to include("日付")
        expect(csv).to include("応募数")
        expect(csv).to include("投票数")
      end

      it "returns valid CSV format" do
        csv = service.to_csv
        rows = CSV.parse(csv, headers: true)

        expect(rows).to be_a(CSV::Table)
      end
    end

    context "when contest has data" do
      let!(:entry1) { create(:entry, contest: contest, user: create(:user, :confirmed), created_at: 2.days.ago) }
      let!(:entry2) { create(:entry, contest: contest, user: create(:user, :confirmed), created_at: 1.day.ago) }
      let!(:vote1) { create(:vote, entry: entry1, user: create(:user, :confirmed), created_at: 1.day.ago) }

      it "includes daily statistics" do
        csv = service.to_csv
        rows = CSV.parse(csv, headers: true)

        expect(rows.length).to be >= 1
      end

      it "includes entry counts by day" do
        csv = service.to_csv

        expect(csv).to include("応募数")
      end

      it "includes vote counts by day" do
        csv = service.to_csv

        expect(csv).to include("投票数")
      end
    end
  end

  describe "#to_csv with BOM" do
    it "includes UTF-8 BOM at the beginning" do
      csv = service.to_csv

      # UTF-8 BOM is \xEF\xBB\xBF
      expect(csv.bytes[0..2]).to eq([ 0xEF, 0xBB, 0xBF ])
    end

    it "is properly encoded as UTF-8" do
      csv = service.to_csv

      expect(csv.encoding).to eq(Encoding::UTF_8)
    end
  end

  describe "#summary_csv" do
    let!(:user1) { create(:user, :confirmed) }
    let!(:user2) { create(:user, :confirmed) }
    let!(:entry1) { create(:entry, contest: contest, user: user1) }
    let!(:entry2) { create(:entry, contest: contest, user: user2) }
    let!(:vote1) { create(:vote, entry: entry1, user: user2) }

    it "includes summary statistics" do
      csv = service.summary_csv

      expect(csv).to include("総応募数")
      expect(csv).to include("総投票数")
      expect(csv).to include("参加者数")
    end

    it "includes correct counts" do
      csv = service.summary_csv
      rows = CSV.parse(csv, headers: true)

      # Find the row with total entries
      expect(csv).to include("2") # 2 entries
      expect(csv).to include("1") # 1 vote
    end
  end

  describe "#entries_csv" do
    let!(:spot) { create(:spot, contest: contest, name: "テストスポット") }
    let!(:entry1) { create(:entry, contest: contest, user: create(:user, :confirmed, name: "参加者A"), spot: spot, title: "作品A") }
    let!(:entry2) { create(:entry, contest: contest, user: create(:user, :confirmed, name: "参加者B"), title: "作品B") }

    it "includes entry details" do
      csv = service.entries_csv
      rows = CSV.parse(csv, headers: true)

      expect(rows.headers).to include("タイトル")
      expect(rows.headers).to include("投稿者")
      expect(rows.headers).to include("スポット")
      expect(rows.headers).to include("投票数")
    end

    it "includes all entries" do
      csv = service.entries_csv

      expect(csv).to include("作品A")
      expect(csv).to include("作品B")
      expect(csv).to include("参加者A")
      expect(csv).to include("参加者B")
    end

    it "includes spot name" do
      csv = service.entries_csv

      expect(csv).to include("テストスポット")
    end
  end
end
