# frozen_string_literal: true

require "rails_helper"

RSpec.describe ModerationResult, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:entry) }
    it { is_expected.to belong_to(:reviewed_by).class_name("User").optional }
  end

  describe "validations" do
    subject { build(:moderation_result) }

    it { is_expected.to validate_presence_of(:provider) }

    describe "entry_id uniqueness" do
      let(:entry) { create(:entry) }
      let!(:existing_result) { create(:moderation_result, entry: entry) }

      it "does not allow duplicate moderation results for the same entry" do
        duplicate = build(:moderation_result, entry: entry)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:entry_id]).to include("はすでに使用されています")
      end
    end

    describe "max_confidence" do
      it "allows nil value" do
        result = build(:moderation_result, max_confidence: nil)
        expect(result).to be_valid
      end

      it "allows values between 0 and 100" do
        result = build(:moderation_result, max_confidence: 50.0)
        expect(result).to be_valid
      end

      it "rejects values less than 0" do
        result = build(:moderation_result, max_confidence: -1)
        expect(result).not_to be_valid
        expect(result.errors[:max_confidence]).to be_present
      end

      it "rejects values greater than 100" do
        result = build(:moderation_result, max_confidence: 101)
        expect(result).not_to be_valid
        expect(result.errors[:max_confidence]).to be_present
      end
    end
  end

  describe "enums" do
    it {
      is_expected.to define_enum_for(:status)
        .with_values(pending: 0, approved: 1, rejected: 2, requires_review: 3)
        .with_prefix(:moderation)
    }
  end

  describe "scopes" do
    let!(:pending_result) { create(:moderation_result, :pending) }
    let!(:approved_result) { create(:moderation_result, :approved) }
    let!(:requires_review_result) { create(:moderation_result, :requires_review) }
    let!(:reviewed_result) { create(:moderation_result, :approved, :reviewed) }

    describe ".pending_review" do
      it "returns pending and requires_review results" do
        results = ModerationResult.pending_review
        expect(results).to include(pending_result, requires_review_result)
        expect(results).not_to include(approved_result)
      end
    end

    describe ".reviewed" do
      it "returns results with reviewed_at present" do
        expect(ModerationResult.reviewed).to include(reviewed_result)
        expect(ModerationResult.reviewed).not_to include(pending_result)
      end
    end

    describe ".by_provider" do
      let!(:rekognition_result) { create(:moderation_result, provider: "rekognition") }
      let!(:other_result) { create(:moderation_result, provider: "other_provider") }

      it "filters by provider" do
        expect(ModerationResult.by_provider("rekognition")).to include(rekognition_result)
        expect(ModerationResult.by_provider("rekognition")).not_to include(other_result)
      end
    end
  end

  describe "instance methods" do
    describe "#reviewed?" do
      it "returns true when reviewed_at is present" do
        result = build(:moderation_result, reviewed_at: Time.current)
        expect(result.reviewed?).to be true
      end

      it "returns false when reviewed_at is nil" do
        result = build(:moderation_result, reviewed_at: nil)
        expect(result.reviewed?).to be false
      end
    end

    describe "#violation_detected?" do
      it "returns true when labels are present and not empty" do
        result = build(:moderation_result, :with_violation)
        expect(result.violation_detected?).to be true
      end

      it "returns false when labels are nil" do
        result = build(:moderation_result, labels: nil)
        expect(result.violation_detected?).to be false
      end

      it "returns false when labels are empty" do
        result = build(:moderation_result, labels: [])
        expect(result.violation_detected?).to be false
      end
    end

    describe "#mark_reviewed!" do
      let(:result) { create(:moderation_result, :requires_review) }
      let(:reviewer) { create(:user, :admin, :confirmed) }

      context "when approving" do
        it "updates the result with approved status" do
          result.mark_reviewed!(reviewer: reviewer, approved: true, note: "問題なし")

          expect(result.reload).to be_moderation_approved
          expect(result.reviewed_by).to eq(reviewer)
          expect(result.reviewed_at).to be_present
          expect(result.review_note).to eq("問題なし")
        end
      end

      context "when rejecting" do
        it "updates the result with rejected status" do
          result.mark_reviewed!(reviewer: reviewer, approved: false, note: "不適切な内容")

          expect(result.reload).to be_moderation_rejected
          expect(result.reviewed_by).to eq(reviewer)
          expect(result.reviewed_at).to be_present
          expect(result.review_note).to eq("不適切な内容")
        end
      end

      context "without note" do
        it "allows nil note" do
          result.mark_reviewed!(reviewer: reviewer, approved: true)

          expect(result.reload).to be_moderation_approved
          expect(result.review_note).to be_nil
        end
      end
    end
  end
end
