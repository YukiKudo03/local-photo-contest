# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpotMergeService do
  describe "#merge" do
    let!(:contest) { create(:contest, :published) }
    let!(:primary_spot) { create(:spot, :with_coordinates, contest: contest, name: "メインスポット") }
    let!(:duplicate_spot) { create(:spot, :with_coordinates, contest: contest, name: "重複スポット") }

    subject(:service) { described_class.new(primary_spot, duplicate_spot) }

    context "when merging two spots" do
      it "marks the duplicate spot as merged into primary" do
        service.merge

        duplicate_spot.reload
        expect(duplicate_spot.merged_into_id).to eq(primary_spot.id)
      end

      it "sets merged_at timestamp on duplicate" do
        service.merge

        duplicate_spot.reload
        expect(duplicate_spot.merged_at).to be_within(1.second).of(Time.current)
      end

      it "keeps the primary spot unchanged" do
        service.merge

        primary_spot.reload
        expect(primary_spot.merged_into_id).to be_nil
      end
    end

    context "when duplicate spot has entries" do
      let!(:entry1) { create(:entry, contest: contest, spot: duplicate_spot, title: "作品1") }
      let!(:entry2) { create(:entry, contest: contest, spot: duplicate_spot, title: "作品2") }
      let!(:primary_entry) { create(:entry, contest: contest, spot: primary_spot, title: "メイン作品") }

      it "moves entries from duplicate to primary spot" do
        service.merge

        expect(entry1.reload.spot).to eq(primary_spot)
        expect(entry2.reload.spot).to eq(primary_spot)
      end

      it "keeps existing entries on primary spot" do
        service.merge

        expect(primary_entry.reload.spot).to eq(primary_spot)
      end

      it "returns the count of moved entries" do
        result = service.merge

        expect(result[:entries_moved]).to eq(2)
      end
    end

    context "when duplicate spot has votes" do
      let!(:user1) { create(:user, :confirmed) }
      let!(:user2) { create(:user, :confirmed) }
      let!(:user3) { create(:user, :confirmed) }
      let!(:duplicate_vote1) { create(:spot_vote, spot: duplicate_spot, user: user1) }
      let!(:duplicate_vote2) { create(:spot_vote, spot: duplicate_spot, user: user2) }
      let!(:primary_vote) { create(:spot_vote, spot: primary_spot, user: user3) }

      it "moves votes from duplicate to primary spot" do
        service.merge

        expect(user1.spot_votes.find_by(spot: primary_spot)).to be_present
        expect(user2.spot_votes.find_by(spot: primary_spot)).to be_present
      end

      it "keeps existing votes on primary spot" do
        service.merge

        expect(user3.spot_votes.find_by(spot: primary_spot)).to be_present
      end

      it "returns the count of moved votes" do
        result = service.merge

        expect(result[:votes_moved]).to eq(2)
      end

      context "when user already voted on primary spot" do
        let!(:conflicting_vote) { create(:spot_vote, spot: primary_spot, user: user1) }

        it "does not create duplicate vote" do
          service.merge

          expect(primary_spot.spot_votes.where(user: user1).count).to eq(1)
        end

        it "removes the duplicate vote" do
          service.merge

          expect(duplicate_spot.spot_votes.where(user: user1).count).to eq(0)
        end
      end
    end

    context "when duplicate spot has discovery information" do
      let!(:discoverer) { create(:user, :confirmed) }
      let!(:duplicate_spot) do
        create(:spot, :discovered, contest: contest, discovered_by: discoverer)
      end

      it "preserves discovery info in merge history" do
        result = service.merge

        expect(result[:preserved_discovery]).to include(
          discovered_by_id: discoverer.id,
          discovery_status: "discovered"
        )
      end
    end

    context "with validation errors" do
      it "raises error when trying to merge spot into itself" do
        self_service = described_class.new(primary_spot, primary_spot)

        expect { self_service.merge }.to raise_error(SpotMergeService::MergeError, /cannot merge a spot into itself/i)
      end

      it "raises error when spots are from different contests" do
        other_contest = create(:contest, :published)
        other_spot = create(:spot, contest: other_contest)
        cross_service = described_class.new(primary_spot, other_spot)

        expect { cross_service.merge }.to raise_error(SpotMergeService::MergeError, /must be from the same contest/i)
      end

      it "raises error when duplicate spot is already merged" do
        duplicate_spot.update!(merged_into_id: primary_spot.id)

        expect { service.merge }.to raise_error(SpotMergeService::MergeError, /already merged/i)
      end
    end

    context "with transaction safety" do
      it "rolls back all changes if an error occurs" do
        entry = create(:entry, contest: contest, spot: duplicate_spot)

        allow(duplicate_spot).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)

        expect { service.merge rescue nil }.not_to change { entry.reload.spot_id }
      end
    end
  end

  describe "#preview" do
    let!(:contest) { create(:contest, :published) }
    let!(:primary_spot) { create(:spot, contest: contest) }
    let!(:duplicate_spot) { create(:spot, contest: contest) }

    subject(:service) { described_class.new(primary_spot, duplicate_spot) }

    before do
      create_list(:entry, 3, contest: contest, spot: duplicate_spot)
      create_list(:spot_vote, 2, spot: duplicate_spot)
    end

    it "returns preview without making changes" do
      preview = service.preview

      expect(preview[:entries_to_move]).to eq(3)
      expect(preview[:votes_to_move]).to eq(2)
      expect(duplicate_spot.reload.merged_into_id).to be_nil
    end
  end
end
