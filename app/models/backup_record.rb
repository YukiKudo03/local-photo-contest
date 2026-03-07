# frozen_string_literal: true

class BackupRecord < ApplicationRecord
  enum :status, { pending: 0, in_progress: 1, completed: 2, failed: 3 }

  validates :backup_type, presence: true, inclusion: { in: %w[daily weekly manual] }
  validates :database_name, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(status: :completed) }
  scope :daily_backups, -> { where(backup_type: "daily") }
  scope :weekly_backups, -> { where(backup_type: "weekly") }

  def duration
    return nil unless started_at && completed_at
    completed_at - started_at
  end
end
