# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscoverySpotService do
  describe ".create_discovered_spot" do
    let(:contest) { create(:contest, :published) }
    let(:user) { create(:user) }
    let(:entry) { build(:entry, contest: contest, user: user) }
    let(:spot_name) { "新しいスポット" }
    let(:latitude) { 35.6580339 }
    let(:longitude) { 139.7016358 }
    let(:comment) { "素敵な場所です" }

    it "creates a new discovered spot" do
      expect {
        described_class.create_discovered_spot(
          entry: entry,
          name: spot_name,
          latitude: latitude,
          longitude: longitude,
          comment: comment
        )
      }.to change(Spot, :count).by(1)
    end

    it "sets discovery_status to discovered" do
      spot = described_class.create_discovered_spot(
        entry: entry,
        name: spot_name,
        latitude: latitude,
        longitude: longitude
      )
      expect(spot.discovery_discovered?).to be true
    end

    it "sets discovered_by to the entry user" do
      spot = described_class.create_discovered_spot(
        entry: entry,
        name: spot_name,
        latitude: latitude,
        longitude: longitude
      )
      expect(spot.discovered_by).to eq(user)
    end

    it "sets discovered_at to current time" do
      spot = described_class.create_discovered_spot(
        entry: entry,
        name: spot_name,
        latitude: latitude,
        longitude: longitude
      )
      expect(spot.discovered_at).to be_within(1.second).of(Time.current)
    end

    it "creates a notification for the organizer" do
      expect {
        described_class.create_discovered_spot(
          entry: entry,
          name: spot_name,
          latitude: latitude,
          longitude: longitude
        )
      }.to change(Notification, :count).by(1)
    end

    it "creates notification with correct attributes" do
      spot = described_class.create_discovered_spot(
        entry: entry,
        name: spot_name,
        latitude: latitude,
        longitude: longitude
      )
      notification = Notification.last
      expect(notification.user).to eq(contest.user)
      expect(notification.notification_type).to eq("spot_discovered")
    end
  end

  describe ".certify_spot" do
    let(:certifier) { create(:user) }

    context "when spot is pending certification" do
      let(:spot) { create(:spot, :discovered) }

      it "changes status to certified" do
        described_class.certify_spot(spot: spot, user: certifier)
        expect(spot.reload.discovery_certified?).to be true
      end

      it "sets certified_by to the certifier" do
        described_class.certify_spot(spot: spot, user: certifier)
        expect(spot.reload.certified_by).to eq(certifier)
      end

      it "creates a notification for the discoverer" do
        expect {
          described_class.certify_spot(spot: spot, user: certifier)
        }.to change(Notification, :count).by(1)
      end

      it "creates notification with spot_certified type" do
        described_class.certify_spot(spot: spot, user: certifier)
        notification = Notification.last
        expect(notification.user).to eq(spot.discovered_by)
        expect(notification.notification_type).to eq("spot_certified")
      end
    end

    context "when spot is not pending certification" do
      let(:spot) { create(:spot, :certified) }

      it "raises ArgumentError" do
        expect {
          described_class.certify_spot(spot: spot, user: certifier)
        }.to raise_error(ArgumentError, "Spot is not pending certification")
      end
    end
  end

  describe ".reject_spot" do
    let(:rejector) { create(:user) }
    let(:reason) { "不適切なスポットです" }

    context "when spot is pending certification" do
      let(:spot) { create(:spot, :discovered) }

      it "changes status to rejected" do
        described_class.reject_spot(spot: spot, user: rejector, reason: reason)
        expect(spot.reload.discovery_rejected?).to be true
      end

      it "sets rejection_reason" do
        described_class.reject_spot(spot: spot, user: rejector, reason: reason)
        expect(spot.reload.rejection_reason).to eq(reason)
      end

      it "creates a notification for the discoverer" do
        expect {
          described_class.reject_spot(spot: spot, user: rejector, reason: reason)
        }.to change(Notification, :count).by(1)
      end

      it "creates notification with spot_rejected type" do
        described_class.reject_spot(spot: spot, user: rejector, reason: reason)
        notification = Notification.last
        expect(notification.user).to eq(spot.discovered_by)
        expect(notification.notification_type).to eq("spot_rejected")
      end
    end

    context "when spot is not pending certification" do
      let(:spot) { create(:spot, :certified) }

      it "raises ArgumentError" do
        expect {
          described_class.reject_spot(spot: spot, user: rejector, reason: reason)
        }.to raise_error(ArgumentError, "Spot is not pending certification")
      end
    end

    context "when reason is blank" do
      let(:spot) { create(:spot, :discovered) }

      it "raises ArgumentError" do
        expect {
          described_class.reject_spot(spot: spot, user: rejector, reason: "")
        }.to raise_error(ArgumentError, "Rejection reason is required")
      end
    end
  end

  describe ".merge_spots" do
    let(:contest) { create(:contest, :published) }
    let(:target) { create(:spot, :certified, contest: contest, votes_count: 0) }
    let(:source1) { create(:spot, :certified, contest: contest, votes_count: 0) }
    let(:source2) { create(:spot, :certified, contest: contest, votes_count: 0) }

    it "moves entries from sources to target" do
      entry1 = create(:entry, contest: contest, spot: source1)
      entry2 = create(:entry, contest: contest, spot: source2)

      described_class.merge_spots(target: target, sources: [ source1, source2 ])

      expect(entry1.reload.spot).to eq(target)
      expect(entry2.reload.spot).to eq(target)
    end

    it "destroys source spots" do
      described_class.merge_spots(target: target, sources: [ source1, source2 ])

      expect { source1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { source2.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "updates target votes_count after merge" do
      described_class.merge_spots(target: target, sources: [ source1, source2 ])

      # votes_count is recalculated at the end of merge
      expect(target.reload.votes_count).to eq(0)
    end

    it "calls update on spot_vote when user has not voted on target" do
      voter = create(:user, :confirmed)
      source_vote = create(:spot_vote, spot: source1, user: voter)

      expect_any_instance_of(SpotVote).to receive(:update!).with(spot_id: target.id).and_call_original

      described_class.merge_spots(target: target, sources: [ source1 ])
    end

    it "skips duplicate spot_votes when user already voted on target" do
      voter = create(:user, :confirmed)

      # voter has voted on both target and source1
      create(:spot_vote, spot: target, user: voter)
      create(:spot_vote, spot: source1, user: voter)

      # Should not raise UniqueViolation - duplicate is skipped
      expect {
        described_class.merge_spots(target: target, sources: [ source1, source2 ])
      }.not_to raise_error

      # voter keeps their original target vote
      expect(target.reload.spot_votes.where(user_id: voter.id).count).to eq(1)
    end
  end

  describe ".find_nearby_spots" do
    let(:contest) { create(:contest) }
    let(:center_lat) { 35.6580339 }
    let(:center_lng) { 139.7016358 }

    # Spot approximately 30 meters away
    let!(:nearby_spot) do
      create(:spot, contest: contest, latitude: 35.6582339, longitude: 139.7016358)
    end

    # Spot approximately 500 meters away
    let!(:far_spot) do
      create(:spot, contest: contest, latitude: 35.6630339, longitude: 139.7016358)
    end

    it "returns spots within the radius" do
      result = described_class.find_nearby_spots(
        contest: contest,
        latitude: center_lat,
        longitude: center_lng,
        radius_m: 50
      )
      expect(result).to include(nearby_spot)
    end

    it "excludes spots outside the radius" do
      result = described_class.find_nearby_spots(
        contest: contest,
        latitude: center_lat,
        longitude: center_lng,
        radius_m: 50
      )
      expect(result).not_to include(far_spot)
    end

    it "returns empty array when no spots are nearby" do
      result = described_class.find_nearby_spots(
        contest: contest,
        latitude: 0.0,
        longitude: 0.0,
        radius_m: 50
      )
      expect(result).to be_empty
    end

    it "returns empty array when coordinates are blank" do
      result = described_class.find_nearby_spots(
        contest: contest,
        latitude: nil,
        longitude: nil
      )
      expect(result).to be_empty
    end
  end

  describe ".discovery_statistics" do
    let(:contest) { create(:contest, :published) }
    let!(:organizer_spot) { create(:spot, :organizer_created, contest: contest) }
    let!(:discovered_spot) { create(:spot, :discovered, contest: contest) }
    let!(:certified_spot) { create(:spot, :certified, contest: contest) }
    let!(:rejected_spot) { create(:spot, :rejected, contest: contest) }

    it "returns correct total_spots count" do
      stats = described_class.discovery_statistics(contest)
      expect(stats[:total_spots]).to eq(4)
    end

    it "returns correct organizer_created count" do
      stats = described_class.discovery_statistics(contest)
      expect(stats[:organizer_created]).to eq(1)
    end

    it "returns correct discovered count" do
      stats = described_class.discovery_statistics(contest)
      expect(stats[:discovered]).to eq(1)
    end

    it "returns correct certified count" do
      stats = described_class.discovery_statistics(contest)
      expect(stats[:certified]).to eq(1)
    end

    it "returns correct rejected count" do
      stats = described_class.discovery_statistics(contest)
      expect(stats[:rejected]).to eq(1)
    end

    it "returns correct pending_certification count" do
      stats = described_class.discovery_statistics(contest)
      expect(stats[:pending_certification]).to eq(1)
    end

    it "includes challenges_stats" do
      create(:discovery_challenge, contest: contest)
      stats = described_class.discovery_statistics(contest)
      expect(stats[:challenges_stats]).to be_an(Array)
      expect(stats[:challenges_stats].length).to eq(1)
    end
  end

  describe ".discovery_statistics" do
    let(:contest) { create(:contest, :published) }

    context "when organizer notification fails" do
      it "logs error and does not raise" do
        allow(Notification).to receive(:create!).and_call_original
        allow(Notification).to receive(:create!).with(hash_including(notification_type: "spot_discovered")).and_raise(StandardError, "notification error")

        expect(Rails.logger).to receive(:error).with(/Failed to notify organizer/)
        entry = build(:entry, contest: contest, user: create(:user))
        # Should not raise
        expect {
          described_class.create_discovered_spot(
            entry: entry,
            name: "Test",
            latitude: 35.0,
            longitude: 139.0
          )
        }.not_to raise_error
      end
    end
  end

  describe ".certify_spot badge error handling" do
    let(:contest) { create(:contest, :published) }
    let(:certifier) { create(:user) }
    let(:user) { create(:user) }

    it "logs error when badge awarding fails" do
      5.times { create(:spot, :certified, contest: contest, discovered_by: user) }
      spot = create(:spot, :discovered, contest: contest, discovered_by: user)

      allow(DiscoveryBadge).to receive(:create!).and_raise(StandardError, "badge error")
      expect(Rails.logger).to receive(:error).with(/Failed to award badge/)

      described_class.certify_spot(spot: spot, user: certifier)
    end
  end

  describe ".discovery_ranking" do
    let(:contest) { create(:contest, :published) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    before do
      # user1 has 3 certified spots
      3.times { create(:spot, :certified, contest: contest, discovered_by: user1) }
      # user2 has 1 certified spot
      create(:spot, :certified, contest: contest, discovered_by: user2)
      # user1 has 1 discovered (not certified) spot
      create(:spot, :discovered, contest: contest, discovered_by: user1)
    end

    it "returns users ordered by certified spot count" do
      ranking = described_class.discovery_ranking(contest)
      expect(ranking.first).to eq(user1)
      expect(ranking.second).to eq(user2)
    end

    it "only counts certified spots" do
      ranking = described_class.discovery_ranking(contest)
      expect(ranking.first.certified_count).to eq(3)
    end

    it "respects the limit parameter" do
      ranking = described_class.discovery_ranking(contest, limit: 1)
      expect(ranking.to_a.size).to eq(1)
    end
  end

  describe ".discovery_by_area" do
    let(:contest) { create(:contest, :published) }

    it "groups spots by grid coordinates" do
      create(:spot, contest: contest, latitude: 35.6580, longitude: 139.7016)
      create(:spot, contest: contest, latitude: 35.6585, longitude: 139.7016)

      result = described_class.send(:discovery_by_area, contest)
      expect(result).to be_a(Hash)
      expect(result.values.sum).to eq(2)
    end
  end

  describe "badge awarding" do
    let(:contest) { create(:contest, :published) }
    let(:user) { create(:user) }
    let(:certifier) { create(:user) }

    context "when user reaches 5 certified spots" do
      before do
        4.times { create(:spot, :certified, contest: contest, discovered_by: user) }
      end

      it "awards explorer badge" do
        spot = create(:spot, :discovered, contest: contest, discovered_by: user)

        expect {
          described_class.certify_spot(spot: spot, user: certifier)
        }.to change { user.discovery_badges.where(badge_type: :explorer).count }.by(1)
      end
    end

    context "when user reaches 10 certified spots" do
      before do
        9.times { create(:spot, :certified, contest: contest, discovered_by: user) }
        user.discovery_badges.create!(contest: contest, badge_type: :explorer)
      end

      it "awards curator badge" do
        spot = create(:spot, :discovered, contest: contest, discovered_by: user)

        expect {
          described_class.certify_spot(spot: spot, user: certifier)
        }.to change { user.discovery_badges.where(badge_type: :curator).count }.by(1)
      end
    end

    context "when user already has the badge" do
      before do
        5.times { create(:spot, :certified, contest: contest, discovered_by: user) }
        user.discovery_badges.create!(contest: contest, badge_type: :explorer)
      end

      it "does not duplicate badges" do
        spot = create(:spot, :discovered, contest: contest, discovered_by: user)

        expect {
          described_class.certify_spot(spot: spot, user: certifier)
        }.not_to change { user.discovery_badges.where(badge_type: :explorer).count }
      end
    end
  end
end
