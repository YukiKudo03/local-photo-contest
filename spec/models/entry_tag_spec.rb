# frozen_string_literal: true

require "rails_helper"

RSpec.describe EntryTag, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:entry) }
    it { is_expected.to belong_to(:tag) }
  end

  describe "validations" do
    subject { create(:entry_tag) }

    it { is_expected.to validate_uniqueness_of(:entry_id).scoped_to(:tag_id) }
  end

  describe "counter_cache" do
    let(:tag) { create(:tag) }
    let(:entry) { create(:entry) }

    it "increments entries_count on tag when created" do
      expect {
        create(:entry_tag, entry: entry, tag: tag)
      }.to change { tag.reload.entries_count }.by(1)
    end

    it "decrements entries_count on tag when destroyed" do
      entry_tag = create(:entry_tag, entry: entry, tag: tag)
      expect {
        entry_tag.destroy
      }.to change { tag.reload.entries_count }.by(-1)
    end
  end

  describe "factory" do
    it "creates a valid entry_tag" do
      expect(build(:entry_tag)).to be_valid
    end
  end
end
