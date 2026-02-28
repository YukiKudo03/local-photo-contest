# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataExportRequest, type: :model do
  let(:user) { create(:user, :confirmed) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:requested_at) }
  end

  describe "enums" do
    it {
      is_expected.to define_enum_for(:status)
        .with_values(pending: 0, processing: 1, completed: 2, expired: 3)
    }
  end

  describe ".rate_limited?" do
    it "returns true when user has a request within 24 hours" do
      create(:data_export_request, user: user, requested_at: 12.hours.ago)
      expect(described_class.rate_limited?(user)).to be true
    end

    it "returns false when user has no recent request" do
      create(:data_export_request, user: user, requested_at: 25.hours.ago)
      expect(described_class.rate_limited?(user)).to be false
    end

    it "returns false when user has no requests" do
      expect(described_class.rate_limited?(user)).to be false
    end
  end

  describe "#expired?" do
    it "returns true when expires_at is in the past" do
      request = build(:data_export_request, expires_at: 1.day.ago)
      expect(request.expired?).to be true
    end

    it "returns false when expires_at is in the future" do
      request = build(:data_export_request, expires_at: 1.day.from_now)
      expect(request.expired?).to be false
    end

    it "returns false when expires_at is nil" do
      request = build(:data_export_request, expires_at: nil)
      expect(request.expired?).to be false
    end
  end
end
