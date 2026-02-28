# frozen_string_literal: true

class DataExportRequest < ApplicationRecord
  belongs_to :user
  has_one_attached :file

  enum :status, { pending: 0, processing: 1, completed: 2, expired: 3 }

  validates :status, presence: true
  validates :requested_at, presence: true

  def self.rate_limited?(user)
    where(user: user).where("requested_at > ?", 24.hours.ago).exists?
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end
end
