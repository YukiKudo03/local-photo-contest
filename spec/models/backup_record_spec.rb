# frozen_string_literal: true

require "rails_helper"

RSpec.describe BackupRecord, type: :model do
  describe "validations" do
    it { should validate_presence_of(:backup_type) }
    it { should validate_inclusion_of(:backup_type).in_array(%w[daily weekly manual]) }
    it { should validate_presence_of(:database_name) }
  end

  describe "enums" do
    it {
      is_expected.to define_enum_for(:status)
        .with_values(pending: 0, in_progress: 1, completed: 2, failed: 3)
    }
  end

  describe "scopes" do
    let!(:completed_daily) { create(:backup_record, :completed, backup_type: "daily") }
    let!(:completed_weekly) { create(:backup_record, :completed, backup_type: "weekly") }
    let!(:failed_record) { create(:backup_record, :failed) }
    let!(:pending_record) { create(:backup_record) }

    describe ".recent" do
      it "returns records ordered by created_at desc" do
        results = described_class.recent
        expect(results.first.created_at).to be >= results.last.created_at
      end
    end

    describe ".successful" do
      it "returns only completed records" do
        expect(described_class.successful).to contain_exactly(completed_daily, completed_weekly)
      end
    end

    describe ".daily_backups" do
      it "returns only daily backups" do
        results = described_class.daily_backups
        expect(results).to include(completed_daily)
        expect(results).not_to include(completed_weekly)
      end
    end

    describe ".weekly_backups" do
      it "returns only weekly backups" do
        results = described_class.weekly_backups
        expect(results).to include(completed_weekly)
        expect(results).not_to include(completed_daily)
      end
    end
  end

  describe "#duration" do
    it "returns duration in seconds when both timestamps are present" do
      record = build(:backup_record, :completed, started_at: 5.minutes.ago, completed_at: Time.current)
      expect(record.duration).to be_within(1).of(300)
    end

    it "returns nil when started_at is nil" do
      record = build(:backup_record, started_at: nil, completed_at: Time.current)
      expect(record.duration).to be_nil
    end

    it "returns nil when completed_at is nil" do
      record = build(:backup_record, started_at: Time.current, completed_at: nil)
      expect(record.duration).to be_nil
    end
  end
end
