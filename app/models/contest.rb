class Contest < ApplicationRecord
  include Searchable
  include ContestStateMachine
  search_by :title, :description, :theme

  # Associations
  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :area, optional: true
  has_many :entries, dependent: :destroy
  has_many :spots, dependent: :destroy
  has_many :contest_judges, dependent: :destroy
  has_many :judges, through: :contest_judges, source: :user
  has_many :judge_invitations, dependent: :destroy
  has_many :evaluation_criteria, class_name: "EvaluationCriterion", dependent: :destroy
  has_many :contest_rankings, dependent: :destroy
  has_many :discovery_challenges, dependent: :destroy
  has_many :discovery_badges, dependent: :destroy
  has_one_attached :thumbnail
  has_one_attached :analytics_report_pdf

  # Enums
  enum :status, { draft: 0, published: 1, finished: 2 }
  enum :judging_method, { judge_only: 0, vote_only: 1, hybrid: 2 }, prefix: :judging

  # Validations
  validates :title, presence: true, length: { maximum: 100 }
  validates :theme, length: { maximum: 255 }, allow_blank: true
  validates :status, presence: true
  validates :moderation_threshold,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true
  validates :judge_weight,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true
  validates :prize_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 },
            allow_nil: true
  validate :entry_dates_validity
  validate :area_belongs_to_user
  validate :scheduling_dates_validity

  # Scopes
  scope :active, -> { where(deleted_at: nil) }
  scope :not_archived, -> { where(archived_at: nil) }
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }
  scope :pending_auto_publish, -> {
    active.where(status: :draft)
          .where("scheduled_publish_at <= ?", Time.current)
  }
  scope :pending_auto_finish, -> {
    active.where(status: :published)
          .where("scheduled_finish_at <= ?", Time.current)
  }
  scope :pending_auto_archive, -> {
    candidates = where(status: :finished)
      .where.not(results_announced_at: nil)
      .where(archived_at: nil)
      .where.not(auto_archive_days: nil)
    ids = candidates.select(&:auto_archive_due?).map(&:id)
    where(id: ids)
  }

  # Instance Methods
  def results_announced?
    results_announced_at.present?
  end

  def ranked_entries
    entries.left_joins(:votes)
           .group(:id)
           .order("COUNT(votes.id) DESC", "entries.created_at ASC")
  end

  def top_entries(limit = 3)
    ranked_entries.limit(limit)
  end

  def judge?(other_user)
    contest_judges.exists?(user: other_user)
  end

  def contest_judge_for(other_user)
    contest_judges.find_by(user: other_user)
  end

  def judge_ranked_entries
    entries.left_joins(judge_evaluations: :evaluation_criterion)
           .group(:id)
           .select(
             "entries.*",
             "COALESCE(AVG(judge_evaluations.score), 0) as average_score",
             "COUNT(DISTINCT judge_evaluations.contest_judge_id) as judge_count"
           )
           .order("average_score DESC", "entries.created_at ASC")
  end

  def top_judge_entries(limit = 3)
    judge_ranked_entries.limit(limit)
  end

  def soft_delete!
    raise "Cannot delete: contest is published" if published?
    update!(deleted_at: Time.current)
  end

  def owned_by?(other_user)
    user_id == other_user.id
  end

  def deleted?
    deleted_at.present?
  end

  def archived?
    archived_at.present?
  end

  def archivable?
    finished? && results_announced? && !archived?
  end

  def archive!
    raise I18n.t('contests.errors.not_archivable') unless archivable?
    update!(archived_at: Time.current)
  end

  def unarchive!
    update!(archived_at: nil)
  end

  def auto_archive_due?
    return false unless results_announced_at && auto_archive_days
    results_announced_at + auto_archive_days.days <= Time.current
  end

  def schedulable_for_publish?
    draft? && !deleted? && scheduled_publish_at.present? && scheduled_publish_at <= Time.current
  end

  def schedulable_for_finish?
    published? && !deleted? && scheduled_finish_at.present? && scheduled_finish_at <= Time.current
  end

  def moderation_enabled?
    moderation_enabled
  end

  def effective_moderation_threshold
    moderation_threshold || 60.0
  end

  def judge_completion_rate
    return 100 unless judging_judge_only? || judging_hybrid?
    return 100 if contest_judges.empty? || entries.empty? || evaluation_criteria.empty?

    total_evaluations_needed = contest_judges.count * entries.count * evaluation_criteria.count
    return 100 if total_evaluations_needed.zero?

    actual_evaluations = JudgeEvaluation.joins(:contest_judge)
                                        .where(contest_judges: { contest_id: id })
                                        .count

    (actual_evaluations.to_f / total_evaluations_needed * 100).round
  end

  def calculated_rankings
    contest_rankings.ordered.includes(entry: [ :user, { photo_attachment: :blob } ])
  end

  def prize_entries
    calculated_rankings.where("rank <= ?", prize_count || 3)
  end

  def effective_prize_count
    prize_count || 3
  end

  # Check if rankings have been calculated
  def rankings_calculated?
    contest_rankings.exists?
  end

  private

  def entry_dates_validity
    return if entry_start_at.blank? || entry_end_at.blank?
    if entry_end_at <= entry_start_at
      errors.add(:entry_end_at, :after_start_date)
    end
  end

  def area_belongs_to_user
    return if area_id.blank?
    return if area&.user_id == user_id

    errors.add(:area_id, :must_be_own_area)
  end

  def scheduling_dates_validity
    if scheduled_publish_at.present? && draft? && scheduled_publish_at_changed?
      if scheduled_publish_at <= Time.current
        errors.add(:scheduled_publish_at, :must_be_future)
      end
    end

    if scheduled_finish_at.present? && scheduled_publish_at.present?
      if scheduled_finish_at <= scheduled_publish_at
        errors.add(:scheduled_finish_at, :must_be_after_publish)
      end
    end

    if judging_deadline_at.present? && entry_end_at.present?
      if judging_deadline_at < entry_end_at
        errors.add(:judging_deadline_at, :must_be_after_entry_end)
      end
    end
  end

  def send_results_notifications
    # Get all participants (users who have entries in this contest)
    participants = User.where(id: entries.select(:user_id)).distinct

    # Get ranked entries for top 3
    ranked = ranked_entries.to_a

    participants.find_each do |participant|
      # Send general results announcement (in-app + email)
      Notification.create_results_announced!(
        user: participant,
        contest: self
      )
      NotificationMailer.results_announced(participant, self).deliver_later

      # Check if user has entries in top 3
      ranked.each_with_index do |entry, index|
        rank = index + 1
        break if rank > 3

        if entry.user_id == participant.id
          Notification.create_entry_ranked!(
            user: participant,
            entry: entry,
            rank: rank
          )
          NotificationMailer.entry_ranked(participant, entry, rank).deliver_later
        end
      end
    end
  end
end
