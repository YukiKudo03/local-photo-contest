# frozen_string_literal: true

require "rails_helper"

RSpec.describe TermsAcceptance, type: :model do
  describe "validations" do
    subject { build(:terms_acceptance) }

    it { is_expected.to validate_presence_of(:accepted_at) }
    it { is_expected.to validate_presence_of(:ip_address) }

    describe "uniqueness of user and terms combination" do
      let(:user) { create(:user) }
      let(:terms) { create(:terms_of_service) }
      let!(:existing_acceptance) { create(:terms_acceptance, user: user, terms_of_service: terms) }

      it "prevents duplicate acceptance for same user and terms" do
        duplicate = build(:terms_acceptance, user: user, terms_of_service: terms)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to include("は既にこの利用規約に同意しています")
      end

      it "allows same user to accept different terms versions" do
        new_terms = create(:terms_of_service)
        new_acceptance = build(:terms_acceptance, user: user, terms_of_service: new_terms)
        expect(new_acceptance).to be_valid
      end

      it "allows different users to accept the same terms" do
        other_user = create(:user)
        other_acceptance = build(:terms_acceptance, user: other_user, terms_of_service: terms)
        expect(other_acceptance).to be_valid
      end
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:terms_of_service) }
  end

  describe "scopes" do
    describe ".recent" do
      let!(:old_acceptance) { create(:terms_acceptance, accepted_at: 2.days.ago) }
      let!(:new_acceptance) { create(:terms_acceptance, accepted_at: 1.hour.ago) }

      it "returns acceptances ordered by accepted_at desc" do
        expect(described_class.recent.first).to eq(new_acceptance)
        expect(described_class.recent.last).to eq(old_acceptance)
      end
    end

    describe ".for_terms" do
      let(:terms1) { create(:terms_of_service) }
      let(:terms2) { create(:terms_of_service) }
      let!(:acceptance1) { create(:terms_acceptance, terms_of_service: terms1) }
      let!(:acceptance2) { create(:terms_acceptance, terms_of_service: terms2) }

      it "returns acceptances for the specified terms" do
        expect(described_class.for_terms(terms1)).to include(acceptance1)
        expect(described_class.for_terms(terms1)).not_to include(acceptance2)
      end
    end
  end
end
