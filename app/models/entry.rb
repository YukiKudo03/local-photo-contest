class Entry < ApplicationRecord
  include Searchable
  include Moderatable
  include EntryNotifications
  search_by :title, :description, :location

  PHOTO_VARIANTS = {
    thumb:  { resize_to_fill: [ 150, 150 ] },
    small:  { resize_to_fill: [ 300, 300 ] },
    medium: { resize_to_limit: [ 600, 600 ] },
    large:  { resize_to_limit: [ 1200, 1200 ] }
  }.freeze

  # MiniMagick compatible options for stripping metadata
  VARIANT_STRIP_OPTIONS = { strip: true }.freeze

  # Associations
  belongs_to :user
  belongs_to :contest
  belongs_to :area, optional: true
  belongs_to :spot, optional: true
  has_one_attached :photo
  has_many :votes, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :judge_evaluations, dependent: :destroy
  has_many :judge_comments, dependent: :destroy
  has_one :moderation_result, dependent: :destroy
  has_one :contest_ranking, dependent: :destroy
  has_many :challenge_entries, dependent: :destroy
  has_many :discovery_challenges, through: :challenge_entries

  # Enums
  enum :location_source, { manual: 0, exif: 1, gps: 2 }, prefix: :location

  # Validations
  validates :photo, presence: true
  validates :title, length: { maximum: 100 }, allow_blank: true
  validates :location, length: { maximum: 255 }, allow_blank: true
  validate :contest_accepting_entries, on: :create
  validate :spot_belongs_to_contest
  validate :spot_required_if_contest_requires

  # Scopes
  scope :by_contest, ->(contest) { where(contest: contest) }
  scope :by_user, ->(user) { where(user: user) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance Methods
  def optimized_photo(size = :medium)
    return nil unless photo.attached?
    photo.variant(**PHOTO_VARIANTS[size], format: :webp)
  end

  def photo_variant(size = :medium)
    return nil unless photo.attached?
    photo.variant(**PHOTO_VARIANTS[size])
  end

  def editable?
    contest.accepting_entries?
  end

  def deletable?
    contest.accepting_entries?
  end

  def owned_by?(other_user)
    user_id == other_user.id
  end

  def voted_by?(other_user)
    votes.exists?(user: other_user)
  end

  def votes_count
    votes.count
  end

  def judge_average_score
    judge_evaluations.average(:score)&.round(2) || 0
  end

  def evaluated_by?(contest_judge)
    judge_evaluations.exists?(contest_judge: contest_judge)
  end

  def judge_comment_from(contest_judge)
    judge_comments.find_by(contest_judge: contest_judge)
  end

  private

  def contest_accepting_entries
    return if contest&.accepting_entries?
    errors.add(:base, :contest_not_accepting)
  end

  def spot_belongs_to_contest
    return unless spot.present?
    return if spot.contest_id == contest_id

    errors.add(:spot, :not_in_contest)
  end

  def spot_required_if_contest_requires
    return unless contest&.require_spot
    return if spot.present?

    errors.add(:spot_id, :blank)
  end
end
