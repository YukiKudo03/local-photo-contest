# frozen_string_literal: true

class AuditLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :target, polymorphic: true, optional: true

  # Actions
  ACTIONS = %w[
    login
    logout
    role_change
    account_suspend
    account_unsuspend
    account_delete
    contest_force_finish
    contest_delete
    moderation_approve
    moderation_reject
    category_create
    category_update
    category_delete
    user_update
    contest_auto_publish
    contest_auto_finish
    contest_auto_archive
    contest_unarchive
  ].freeze

  validates :action, presence: true, inclusion: { in: ACTIONS }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_user, ->(user) { where(user: user) }

  # Serialize details as JSON
  serialize :details, coder: JSON

  # Class method to log an action
  def self.log(action:, user: nil, target: nil, details: {}, ip_address: nil)
    create!(
      action: action,
      user: user,
      target_type: target&.class&.name,
      target_id: target&.id,
      details: details,
      ip_address: ip_address
    )
  end

  # Human readable action name
  def action_name
    I18n.t("audit_log.actions.#{action}", default: action.humanize)
  end

  # Target object (if still exists)
  def target
    return nil unless target_type.present? && target_id.present?

    target_type.constantize.find_by(id: target_id)
  rescue NameError
    nil
  end
end
