class Entry < ApplicationRecord
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

  # Enums
  enum :location_source, { manual: 0, exif: 1, gps: 2 }, prefix: :location
  enum :moderation_status, {
    moderation_pending: 0,
    moderation_approved: 1,
    moderation_hidden: 2,
    moderation_requires_review: 3
  }, prefix: false

  # Validations
  validates :photo, presence: true
  validates :title, length: { maximum: 100 }, allow_blank: true
  validates :location, length: { maximum: 255 }, allow_blank: true
  validate :contest_accepting_entries, on: :create
  validate :photo_content_type
  validate :photo_size
  validate :spot_belongs_to_contest
  validate :spot_required_if_contest_requires

  # Callbacks
  after_create_commit :enqueue_moderation_job
  after_create_commit :broadcast_new_entry_notification
  after_commit :clear_statistics_cache, on: [ :create, :destroy ]

  # Scopes
  scope :by_contest, ->(contest) { where(contest: contest) }
  scope :by_user, ->(user) { where(user: user) }
  scope :recent, -> { order(created_at: :desc) }
  scope :visible, -> { where(moderation_status: [ :moderation_pending, :moderation_approved ]) }
  scope :hidden, -> { where(moderation_status: :moderation_hidden) }
  scope :needs_moderation_review, -> { where(moderation_status: [ :moderation_hidden, :moderation_requires_review ]) }

  # Instance Methods
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
    errors.add(:base, "このコンテストは現在応募を受け付けていません")
  end

  def photo_content_type
    return unless photo.attached?
    unless photo.content_type.in?(%w[image/jpeg image/png image/gif])
      errors.add(:photo, "はJPEG、PNG、GIF形式のみ対応しています")
    end
  end

  def photo_size
    return unless photo.attached?
    if photo.byte_size > 10.megabytes
      errors.add(:photo, "は10MB以下にしてください")
    end
  end

  def spot_belongs_to_contest
    return unless spot.present?
    return if spot.contest_id == contest_id

    errors.add(:spot, "はこのコンテストのスポットではありません")
  end

  def spot_required_if_contest_requires
    return unless contest&.require_spot
    return if spot.present?

    errors.add(:spot_id, "を選択してください")
  end

  def enqueue_moderation_job
    return unless should_enqueue_moderation?

    ModerationJob.perform_later(id)
  end

  def should_enqueue_moderation?
    photo.attached? && contest&.moderation_enabled?
  end

  def broadcast_new_entry_notification
    NotificationBroadcaster.new_entry(self)
  rescue => e
    Rails.logger.error("Failed to broadcast new entry notification: #{e.message}")
  end

  def clear_statistics_cache
    StatisticsService.clear_cache(contest)
  rescue => e
    Rails.logger.error("Failed to clear statistics cache: #{e.message}")
  end
end
