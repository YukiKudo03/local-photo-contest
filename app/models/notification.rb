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
      title: "コンテスト「#{contest.title}」の結果が発表されました",
      body: "あなたが参加したコンテストの結果をご確認ください。"
    )
  end

  def self.create_entry_ranked!(user:, entry:, rank:)
    contest = entry.contest
    rank_label = case rank
    when 1 then "1位"
    when 2 then "2位"
    when 3 then "3位"
    else "#{rank}位"
    end

    create!(
      user: user,
      notifiable: entry,
      notification_type: TYPES[:entry_ranked],
      title: "あなたの作品が#{rank_label}に入賞しました！",
      body: "コンテスト「#{contest.title}」であなたの作品「#{entry.title}」が#{rank_label}に選ばれました。"
    )
  end
end
