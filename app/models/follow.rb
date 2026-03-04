# frozen_string_literal: true

class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User", counter_cache: :followers_count

  validates :follower_id, uniqueness: { scope: :followed_id }
  validate :cannot_follow_self

  scope :by_follower, ->(user) { where(follower: user) }
  scope :by_followed, ->(user) { where(followed: user) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :increment_following_count
  after_create_commit :send_follow_notification
  after_destroy_commit :decrement_following_count

  private

  def cannot_follow_self
    if follower_id == followed_id
      errors.add(:base, I18n.t("errors.messages.cannot_follow_self"))
    end
  end

  def send_follow_notification
    FollowNotificationJob.perform_later(id)
  rescue => e
    Rails.logger.error("Failed to enqueue follow notification: #{e.message}")
  end

  def increment_following_count
    Follow.where(follower_id: follower_id).count.then do |count|
      follower.update_column(:following_count, count)
    end
  end

  def decrement_following_count
    Follow.where(follower_id: follower_id).count.then do |count|
      follower.update_column(:following_count, count)
    end
  end
end
