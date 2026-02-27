# frozen_string_literal: true

class Notification < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :notifiable, polymorphic: true

  # Validations
  validates :notification_type, presence: true
  validates :title, presence: true

  # Scopes
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }

  # Notification types
  TYPES = {
    results_announced: "results_announced",
    entry_ranked: "entry_ranked"
  }.freeze

  # Instance methods
  def read?
    read_at.present?
  end

  def unread?
    !read?
  end

  def mark_as_read!
    update!(read_at: Time.current) if unread?
  end

  # Class methods
  def self.mark_all_as_read!(user)
    for_user(user).unread.update_all(read_at: Time.current)
  end

  def self.create_results_announced!(user: nil, user_id: nil, contest:)
    user ||= User.find(user_id)
    create!(
      user: user,
      notifiable: contest,
      notification_type: TYPES[:results_announced],
      title: I18n.t('notifications.messages.results_announced.title', contest_title: contest.title),
      body: I18n.t('notifications.messages.results_announced.body')
    )
  end

  def self.create_entry_ranked!(user:, entry:, rank:)
    contest = entry.contest
    rank_label = I18n.t('notifications.messages.entry_ranked.rank_label', rank: rank)

    create!(
      user: user,
      notifiable: entry,
      notification_type: TYPES[:entry_ranked],
      title: I18n.t('notifications.messages.entry_ranked.title', rank_label: rank_label),
      body: I18n.t('notifications.messages.entry_ranked.body', contest_title: contest.title, entry_title: entry.title, rank_label: rank_label)
    )
  end
end
