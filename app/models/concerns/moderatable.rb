# frozen_string_literal: true

module Moderatable
  extend ActiveSupport::Concern

  included do
    # Enums
    enum :moderation_status, {
      moderation_pending: 0,
      moderation_approved: 1,
      moderation_hidden: 2,
      moderation_requires_review: 3
    }, prefix: false

    # Scopes
    scope :visible, -> { where(moderation_status: [ :moderation_pending, :moderation_approved ]) }
    scope :hidden, -> { where(moderation_status: :moderation_hidden) }
    scope :needs_moderation_review, -> { where(moderation_status: [ :moderation_hidden, :moderation_requires_review ]) }

    # Validations
    validate :photo_content_type
    validate :photo_size

    # Callbacks
    after_create_commit :enqueue_moderation_job
  end

  private

  def photo_content_type
    return unless photo.attached?
    unless photo.content_type.in?(%w[image/jpeg image/png image/gif])
      errors.add(:photo, :content_type_invalid)
    end
  end

  def photo_size
    return unless photo.attached?
    if photo.byte_size > 10.megabytes
      errors.add(:photo, :file_size_too_large)
    end
  end

  def enqueue_moderation_job
    return unless should_enqueue_moderation?

    ModerationJob.perform_later(id)
  end

  def should_enqueue_moderation?
    photo.attached? && contest&.moderation_enabled?
  end
end
