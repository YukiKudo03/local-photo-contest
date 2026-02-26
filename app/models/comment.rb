# frozen_string_literal: true

class Comment < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :entry

  # Validations
  validates :body, presence: true, length: { maximum: 1000 }

  # Callbacks
  after_create_commit :send_comment_notification_email

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :oldest, -> { order(created_at: :asc) }

  # Delegation
  delegate :contest, to: :entry

  private

  def send_comment_notification_email
    NotificationMailer.comment_posted(self).deliver_later
  rescue => e
    Rails.logger.error("Failed to send comment notification email: #{e.message}")
  end
end
