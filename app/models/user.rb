class User < ApplicationRecord
  include TutorialTrackable

  # Include devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable

  # Associations
  has_many :terms_acceptances, dependent: :destroy
  has_many :areas, dependent: :destroy
  has_many :contests, dependent: :destroy
  has_many :contest_templates, dependent: :destroy
  has_many :entries, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :voted_entries, through: :votes, source: :entry
  has_many :notifications, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :contest_judges, dependent: :destroy
  has_many :judging_contests, through: :contest_judges, source: :contest
  has_many :discovered_spots, class_name: "Spot", foreign_key: :discovered_by_id, dependent: :nullify
  has_many :certified_spots, class_name: "Spot", foreign_key: :certified_by_id, dependent: :nullify
  has_many :spot_votes, dependent: :destroy
  has_many :data_export_requests, dependent: :destroy
  has_many :discovery_badges, dependent: :destroy
  has_many :tutorial_progresses, dependent: :destroy
  has_many :api_tokens, dependent: :destroy
  has_many :webhooks, dependent: :destroy
  has_one_attached :avatar

  # Role enum
  enum :role, { participant: 0, organizer: 1, admin: 2 }

  # Account deletion scopes
  scope :pending_deletion, -> { where.not(deletion_scheduled_at: nil).where("deletion_scheduled_at <= ?", Time.current) }
  scope :deletion_reminder_due, -> {
    target_date = 7.days.from_now.to_date
    where.not(deletion_scheduled_at: nil)
      .where(deletion_scheduled_at: target_date.beginning_of_day..target_date.end_of_day)
  }

  # Email preference mapping
  EMAIL_PREFERENCE_MAP = {
    entry_submitted: :email_on_entry_submitted,
    comment: :email_on_comment,
    vote: :email_on_vote,
    results: :email_on_results,
    digest: :email_digest,
    judging: :email_on_judging
  }.freeze

  # Validations
  validates :role, presence: true
  validates :name, length: { maximum: 50 }, allow_blank: true
  validates :bio, length: { maximum: 500 }, allow_blank: true
  validate :avatar_content_type
  validate :avatar_size

  # Callbacks
  before_create :generate_unsubscribe_token

  # Display name (returns name if set, otherwise email)
  def display_name
    name.presence || email.split("@").first
  end

  # Initial for avatar placeholder
  def initial
    display_name.first.upcase
  end

  # Check if user has organizer privileges (organizer or admin)
  def organizer?
    self.role.in?(%w[organizer admin])
  end

  # Check if user is a judge for a specific contest
  def judge_for?(contest)
    contest_judges.exists?(contest: contest)
  end

  # Check if user is a judge for any contest
  def judge?
    contest_judges.exists?
  end

  # Check if user has accepted the current terms of service
  def accepted_current_terms?
    current_terms = TermsOfService.current
    return true if current_terms.nil?

    terms_acceptances.exists?(terms_of_service: current_terms)
  end

  # Accept terms of service and record the acceptance
  def accept_terms!(terms_of_service, ip_address)
    terms_acceptances.create!(
      terms_of_service: terms_of_service,
      accepted_at: Time.current,
      ip_address: ip_address
    )
  end

  # Tutorial methods
  def tutorial_progress_for(tutorial_type)
    tutorial_progresses.find_or_initialize_by(tutorial_type: tutorial_type)
  end

  def tutorial_completed?(tutorial_type)
    tutorial_progresses.exists?(tutorial_type: tutorial_type, completed: true)
  end

  def tutorial_skipped?(tutorial_type)
    tutorial_progresses.exists?(tutorial_type: tutorial_type, skipped: true)
  end

  def should_show_tutorial?(tutorial_type)
    return false unless tutorial_enabled?

    progress = tutorial_progresses.find_by(tutorial_type: tutorial_type)
    progress.nil? || (!progress.completed? && !progress.skipped?)
  end

  def onboarding_tutorial_type
    TutorialStep.onboarding_type_for_role(role)
  end

  def should_show_onboarding?
    return false unless tutorial_enabled?

    onboarding_type = onboarding_tutorial_type
    return false if onboarding_type.nil?

    should_show_tutorial?(onboarding_type)
  end

  def tutorial_enabled?
    tutorial_settings&.dig("show_tutorials") != false
  end

  def context_help_enabled?
    tutorial_settings&.dig("show_context_help") != false
  end

  def reduced_motion?
    tutorial_settings&.dig("reduced_motion") == true
  end

  def update_tutorial_settings(settings)
    update(tutorial_settings: (tutorial_settings || {}).merge(settings))
  end

  # Account deletion methods
  def request_deletion!
    update!(
      deletion_requested_at: Time.current,
      deletion_scheduled_at: 30.days.from_now
    )
  end

  def cancel_deletion!
    update!(
      deletion_requested_at: nil,
      deletion_scheduled_at: nil
    )
  end

  def deletion_requested?
    deletion_requested_at.present?
  end

  def days_until_deletion
    return nil unless deletion_scheduled_at
    ((deletion_scheduled_at - Time.current) / 1.day).ceil
  end

  def email_enabled?(notification_type)
    column = EMAIL_PREFERENCE_MAP[notification_type]
    return true unless column
    send(column)
  end

  def ensure_unsubscribe_token!
    return unsubscribe_token if unsubscribe_token.present?
    update_column(:unsubscribe_token, SecureRandom.urlsafe_base64(32))
    unsubscribe_token
  end

  private

  def avatar_content_type
    return unless avatar.attached?
    unless avatar.content_type.in?(%w[image/jpeg image/png image/gif])
      errors.add(:avatar, :content_type_invalid)
    end
  end

  def generate_unsubscribe_token
    self.unsubscribe_token ||= SecureRandom.urlsafe_base64(32)
  end

  def avatar_size
    return unless avatar.attached?
    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, :file_size_too_large)
    end
  end
end
