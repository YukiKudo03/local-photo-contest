require 'rails_helper'

RSpec.describe Vote, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:entry) }
  end

  describe 'validations' do
    context 'uniqueness' do
      let(:user) { create(:user, :confirmed) }
      let(:entry) { create(:entry) }

      it 'allows one vote per user per entry' do
        create(:vote, user: user, entry: entry)
        duplicate_vote = build(:vote, user: user, entry: entry)

        expect(duplicate_vote).not_to be_valid
        expect(duplicate_vote.errors[:user_id]).to be_present
      end

      it 'allows different users to vote on same entry' do
        other_user = create(:user, :confirmed)
        create(:vote, user: user, entry: entry)
        other_vote = build(:vote, user: other_user, entry: entry)

        expect(other_vote).to be_valid
      end
    end

    context 'cannot vote own entry' do
      it 'rejects vote on own entry' do
        entry = create(:entry)
        vote = build(:vote, user: entry.user, entry: entry)

        expect(vote).not_to be_valid
        expect(vote.errors[:base]).to include("自分の作品には投票できません")
      end
    end

    context 'contest accepting votes' do
      it 'rejects vote when contest is not accepting entries' do
        # Create entry while contest is published, then finish the contest
        entry = create(:entry)
        entry.contest.update!(status: :finished)

        voter = create(:user, :confirmed)
        vote = build(:vote, user: voter, entry: entry)

        expect(vote).not_to be_valid
        expect(vote.errors[:base]).to include("このコンテストは現在投票を受け付けていません")
      end

      it 'accepts vote when contest is accepting entries' do
        entry = create(:entry)
        voter = create(:user, :confirmed)
        vote = build(:vote, user: voter, entry: entry)

        expect(vote).to be_valid
      end
    end
  end

  describe 'scopes' do
    let!(:user) { create(:user, :confirmed) }
    let!(:entry) { create(:entry) }
    let!(:vote) { create(:vote, user: user, entry: entry) }

    describe '.by_user' do
      it 'returns votes for the specified user' do
        other_vote = create(:vote, entry: entry)

        expect(Vote.by_user(user)).to include(vote)
        expect(Vote.by_user(user)).not_to include(other_vote)
      end
    end

    describe '.by_entry' do
      it 'returns votes for the specified entry' do
        other_entry = create(:entry)
        other_vote = create(:vote, user: user, entry: other_entry)

        expect(Vote.by_entry(entry)).to include(vote)
        expect(Vote.by_entry(entry)).not_to include(other_vote)
      end
    end

    describe '.recent' do
      it 'returns votes in descending order by created_at' do
        newer_vote = create(:vote, entry: entry)

        expect(Vote.recent.first).to eq(newer_vote)
        expect(Vote.recent.last).to eq(vote)
      end
    end
  end

  describe 'delegation' do
    it 'delegates contest to entry' do
      entry = create(:entry)
      vote = create(:vote, entry: entry)

      expect(vote.contest).to eq(entry.contest)
    end
  end

  describe 'counter_cache' do
    it 'increments votes_count on entry when vote is created' do
      entry = create(:entry)
      expect {
        create(:vote, entry: entry)
      }.to change { entry.reload.votes_count }.from(0).to(1)
    end

    it 'decrements votes_count on entry when vote is destroyed' do
      entry = create(:entry)
      vote = create(:vote, entry: entry)
      expect {
        vote.destroy
      }.to change { entry.reload.votes_count }.from(1).to(0)
    end

    it 'tracks multiple votes accurately' do
      entry = create(:entry)
      votes = 3.times.map { create(:vote, entry: entry) }
      expect(entry.reload.votes_count).to eq(3)

      votes.first.destroy
      expect(entry.reload.votes_count).to eq(2)
    end
  end

  describe 'callbacks error handling' do
    it 'does not raise when broadcast_vote_update fails' do
      allow(NotificationBroadcaster).to receive(:vote_update).and_raise(StandardError, "broadcast error")
      expect { create(:vote) }.not_to raise_error
    end

    it 'does not raise when clear_statistics_cache fails' do
      allow(StatisticsService).to receive(:clear_cache).and_raise(StandardError, "cache error")
      expect { create(:vote) }.not_to raise_error
    end

    it 'does not raise when send_vote_notification_email fails' do
      allow(NotificationMailer).to receive(:entry_voted).and_raise(StandardError, "mail error")
      expect { create(:vote) }.not_to raise_error
    end

    it 'logs error when broadcast_vote_update fails' do
      vote = create(:vote)
      allow(NotificationBroadcaster).to receive(:vote_update).and_raise(StandardError, "broadcast error")
      expect(Rails.logger).to receive(:error).with(/Failed to broadcast vote update/)
      vote.send(:broadcast_vote_update)
    end
  end

  describe 'database constraints' do
    let(:user) { create(:user, :confirmed) }
    let(:entry) { create(:entry) }

    it 'enforces uniqueness at database level' do
      # Create first vote normally
      create(:vote, user: user, entry: entry)

      # Try to create duplicate by bypassing application validations
      duplicate = Vote.new(user: user, entry: entry)

      expect {
        duplicate.save(validate: false)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows the same user to vote on different entries' do
      other_entry = create(:entry)

      vote1 = create(:vote, user: user, entry: entry)
      vote2 = create(:vote, user: user, entry: other_entry)

      expect(vote1).to be_persisted
      expect(vote2).to be_persisted
    end
  end
end
