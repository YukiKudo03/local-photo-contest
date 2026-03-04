# frozen_string_literal: true

require "rails_helper"

RSpec.describe SimilarEntriesService do
  let(:user) { create(:user, :confirmed) }
  let(:other_user) { create(:user, :confirmed) }
  let(:contest) { create(:contest, :published) }
  let(:other_contest) { create(:contest, :published) }
  let(:source_entry) { create(:entry, :with_exif, user: user, contest: contest) }

  describe "#find" do
    context "same camera model" do
      let!(:same_camera_entry) { create(:entry, :with_exif, user: other_user, contest: other_contest) }

      it "includes entries with the same camera model" do
        other_contest.finish!
        result = described_class.new(source_entry).find
        expect(result).to include(same_camera_entry)
      end
    end

    context "source entry exclusion" do
      it "excludes the source entry itself" do
        result = described_class.new(source_entry).find
        expect(result).not_to include(source_entry)
      end
    end

    context "same contest" do
      let!(:same_contest_entry) { create(:entry, user: other_user, contest: contest) }

      it "includes entries from the same contest" do
        result = described_class.new(source_entry).find
        expect(result).to include(same_contest_entry)
      end
    end

    context "same user" do
      let!(:same_user_entry) { create(:entry, user: user, contest: other_contest) }

      it "includes entries by the same user" do
        other_contest.finish!
        result = described_class.new(source_entry).find
        expect(result).to include(same_user_entry)
      end
    end

    context "limit" do
      before do
        8.times { create(:entry, user: other_user, contest: contest) }
      end

      it "respects the limit parameter" do
        result = described_class.new(source_entry, limit: 4).find
        expect(result.size).to be <= 4
      end

      it "defaults to limit of 6" do
        result = described_class.new(source_entry).find
        expect(result.size).to be <= 6
      end
    end

    context "hidden entries" do
      let!(:hidden_entry) { create(:entry, user: other_user, contest: contest, moderation_status: :moderation_hidden) }

      it "excludes hidden entries" do
        result = described_class.new(source_entry).find
        expect(result).not_to include(hidden_entry)
      end
    end

    context "same tags" do
      let!(:tagged_entry) { create(:entry, user: other_user, contest: contest) }
      let(:tag) { create(:tag, name: "nature") }

      before do
        create(:entry_tag, entry: source_entry, tag: tag)
        create(:entry_tag, entry: tagged_entry, tag: tag)
      end

      it "includes entries with the same tags" do
        result = described_class.new(source_entry).find
        expect(result).to include(tagged_entry)
      end
    end

    context "perceptually similar (dHash)" do
      let!(:similar_entry) { create(:entry, user: other_user, contest: contest, image_hash: "0000000000000001") }

      it "includes entries with similar image hash" do
        source_entry.update_columns(image_hash: "0000000000000000")
        result = described_class.new(source_entry.reload).find
        expect(result).to include(similar_entry)
      end
    end
  end
end
