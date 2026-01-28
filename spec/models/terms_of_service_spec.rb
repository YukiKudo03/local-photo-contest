# frozen_string_literal: true

require "rails_helper"

RSpec.describe TermsOfService, type: :model do
  describe "validations" do
    subject { build(:terms_of_service, version: "v1.0") }

    it { is_expected.to validate_presence_of(:version) }
    it { is_expected.to validate_uniqueness_of(:version) }
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_presence_of(:published_at) }
  end

  describe "associations" do
    it { is_expected.to have_many(:terms_acceptances).dependent(:restrict_with_error) }
  end

  describe "scopes" do
    describe ".published" do
      let!(:published_terms) { create(:terms_of_service, published_at: 1.day.ago) }
      let!(:future_terms) { create(:terms_of_service, :future) }

      it "returns only published terms" do
        expect(described_class.published).to include(published_terms)
        expect(described_class.published).not_to include(future_terms)
      end
    end

    describe ".by_version" do
      let!(:terms_v1) { create(:terms_of_service, version: "1.0") }
      let!(:terms_v2) { create(:terms_of_service, version: "2.0") }

      it "returns terms with matching version" do
        expect(described_class.by_version("1.0")).to include(terms_v1)
        expect(described_class.by_version("1.0")).not_to include(terms_v2)
      end
    end
  end

  describe ".current" do
    context "when there are published terms" do
      let!(:old_terms) { create(:terms_of_service, :old) }
      let!(:recent_terms) { create(:terms_of_service, published_at: 1.hour.ago) }
      let!(:future_terms) { create(:terms_of_service, :future) }

      it "returns the most recently published terms" do
        expect(described_class.current).to eq(recent_terms)
      end
    end

    context "when there are no published terms" do
      let!(:future_terms) { create(:terms_of_service, :future) }

      it "returns nil" do
        expect(described_class.current).to be_nil
      end
    end
  end
end
