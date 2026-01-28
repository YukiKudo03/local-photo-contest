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
end
