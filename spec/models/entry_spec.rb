require 'rails_helper'

RSpec.describe Entry, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:contest) }
    it { should have_one_attached(:photo) }
    it { should have_one(:moderation_result).dependent(:destroy) }
  end

  describe 'enums' do
    it {
      is_expected.to define_enum_for(:moderation_status)
        .with_values(
          moderation_pending: 0,
          moderation_approved: 1,
          moderation_hidden: 2,
          moderation_requires_review: 3
        )
    }
  end

  describe 'validations' do
    context 'photo' do
      it 'requires photo to be present' do
        entry = build(:entry, :without_photo)
        expect(entry).not_to be_valid
        expect(entry.errors[:photo]).to include("を入力してください")
      end

      it 'is valid with a photo attached' do
        entry = build(:entry)
        expect(entry).to be_valid
      end
    end

    context 'title' do
      it 'allows blank title' do
        entry = build(:entry, :without_title)
        expect(entry).to be_valid
      end

      it 'allows title up to 100 characters' do
        entry = build(:entry, :with_long_title)
        expect(entry).to be_valid
      end

      it 'rejects title longer than 100 characters' do
        entry = build(:entry, title: "あ" * 101)
        expect(entry).not_to be_valid
        expect(entry.errors[:title]).to be_present
      end
    end

    context 'location' do
      it 'allows blank location' do
        entry = build(:entry, :without_location)
        expect(entry).to be_valid
      end

      it 'allows location up to 255 characters' do
        entry = build(:entry, :with_long_location)
        expect(entry).to be_valid
      end

      it 'rejects location longer than 255 characters' do
        entry = build(:entry, location: "あ" * 256)
        expect(entry).not_to be_valid
        expect(entry.errors[:location]).to be_present
      end
    end

    context 'contest accepting entries' do
      it 'rejects entry to draft contest' do
        contest = create(:contest, :draft)
        entry = build(:entry, contest: contest)
        expect(entry).not_to be_valid
        expect(entry.errors[:base]).to include("このコンテストは現在応募を受け付けていません")
      end

      it 'rejects entry to finished contest' do
        contest = create(:contest, :finished)
        entry = build(:entry, contest: contest)
        expect(entry).not_to be_valid
        expect(entry.errors[:base]).to include("このコンテストは現在応募を受け付けていません")
      end

      it 'accepts entry to published contest' do
        contest = create(:contest, :published)
        entry = build(:entry, contest: contest)
        expect(entry).to be_valid
      end

      it 'accepts entry to published contest with valid date range' do
        contest = create(:contest, :accepting_entries)
        entry = build(:entry, contest: contest)
        expect(entry).to be_valid
      end

      it 'rejects entry before entry_start_at' do
        contest = create(:contest, :published, entry_start_at: 1.day.from_now, entry_end_at: 2.days.from_now)
        entry = build(:entry, contest: contest)
        expect(entry).not_to be_valid
        expect(entry.errors[:base]).to include("このコンテストは現在応募を受け付けていません")
      end

      it 'rejects entry after entry_end_at' do
        contest = create(:contest, :published, entry_start_at: 2.days.ago, entry_end_at: 1.day.ago)
        entry = build(:entry, contest: contest)
        expect(entry).not_to be_valid
        expect(entry.errors[:base]).to include("このコンテストは現在応募を受け付けていません")
      end
    end
  end

  describe 'scopes' do
    let!(:contest) { create(:contest, :published) }
    let!(:user) { create(:user, :confirmed) }
    let!(:entry1) { create(:entry, contest: contest, user: user) }
    let!(:entry2) { create(:entry, contest: contest) }

    describe '.by_contest' do
      it 'returns entries for the specified contest' do
        other_contest = create(:contest, :published)
        other_entry = create(:entry, contest: other_contest)

        expect(Entry.by_contest(contest)).to include(entry1, entry2)
        expect(Entry.by_contest(contest)).not_to include(other_entry)
      end
    end

    describe '.by_user' do
      it 'returns entries for the specified user' do
        expect(Entry.by_user(user)).to include(entry1)
        expect(Entry.by_user(user)).not_to include(entry2)
      end
    end

    describe '.recent' do
      it 'returns entries in descending order by created_at' do
        expect(Entry.recent.first).to eq(entry2)
        expect(Entry.recent.last).to eq(entry1)
      end
    end

    describe '.visible' do
      let!(:pending_entry) { create(:entry, contest: contest, moderation_status: :moderation_pending) }
      let!(:approved_entry) { create(:entry, contest: contest, moderation_status: :moderation_approved) }
      let!(:hidden_entry) { create(:entry, contest: contest, moderation_status: :moderation_hidden) }
      let!(:review_entry) { create(:entry, contest: contest, moderation_status: :moderation_requires_review) }

      it 'returns pending and approved entries' do
        visible = Entry.visible
        expect(visible).to include(pending_entry, approved_entry)
        expect(visible).not_to include(hidden_entry, review_entry)
      end
    end

    describe '.hidden' do
      let!(:pending_entry) { create(:entry, contest: contest, moderation_status: :moderation_pending) }
      let!(:hidden_entry) { create(:entry, contest: contest, moderation_status: :moderation_hidden) }

      it 'returns only hidden entries' do
        expect(Entry.hidden).to include(hidden_entry)
        expect(Entry.hidden).not_to include(pending_entry)
      end
    end

    describe '.needs_moderation_review' do
      let!(:pending_entry) { create(:entry, contest: contest, moderation_status: :moderation_pending) }
      let!(:hidden_entry) { create(:entry, contest: contest, moderation_status: :moderation_hidden) }
      let!(:review_entry) { create(:entry, contest: contest, moderation_status: :moderation_requires_review) }

      it 'returns hidden and requires_review entries' do
        needs_review = Entry.needs_moderation_review
        expect(needs_review).to include(hidden_entry, review_entry)
        expect(needs_review).not_to include(pending_entry)
      end
    end
  end

  describe 'instance methods' do
    describe '#editable?' do
      it 'returns true when contest is accepting entries' do
        entry = create(:entry)
        expect(entry.editable?).to be true
      end

      it 'returns false when contest is finished' do
        user = create(:user, :confirmed)
        contest = create(:contest, :finished)
        entry = build(:entry, user: user, contest: contest)
        entry.save(validate: false)
        expect(entry.editable?).to be false
      end

      it 'returns false when contest is draft' do
        user = create(:user, :confirmed)
        contest = create(:contest, :draft)
        entry = build(:entry, user: user, contest: contest)
        entry.save(validate: false)
        expect(entry.editable?).to be false
      end
    end

    describe '#deletable?' do
      it 'returns true when contest is accepting entries' do
        entry = create(:entry)
        expect(entry.deletable?).to be true
      end

      it 'returns false when contest is finished' do
        user = create(:user, :confirmed)
        contest = create(:contest, :finished)
        entry = build(:entry, user: user, contest: contest)
        entry.save(validate: false)
        expect(entry.deletable?).to be false
      end
    end

    describe '#owned_by?' do
      let(:user) { create(:user, :confirmed) }
      let(:other_user) { create(:user, :confirmed) }
      let(:entry) { create(:entry, user: user) }

      it 'returns true when user owns the entry' do
        expect(entry.owned_by?(user)).to be true
      end

      it 'returns false when user does not own the entry' do
        expect(entry.owned_by?(other_user)).to be false
      end
    end
  end
end
