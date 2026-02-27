# frozen_string_literal: true

class JudgeInvitation < ApplicationRecord
  # Constants
  TOKEN_EXPIRY_DAYS = 30

  # Associations
  belongs_to :contest
  belongs_to :invited_by, class_name: "User", optional: true
  belongs_to :user, optional: true

  # Enums
  enum :status, { pending: 0, accepted: 1, declined: 2 }

  # Validations
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :contest_id, message: :already_invited }
  validates :token, presence: true, uniqueness: true
  validates :invited_at, presence: true
  validate :email_not_already_judge

  # Callbacks
  before_validation :generate_token, on: :create
  before_validation :set_invited_at, on: :create

  # Scopes
  scope :for_contest, ->(contest) { where(contest: contest) }
  scope :active, -> { pending.where("invited_at > ?", TOKEN_EXPIRY_DAYS.days.ago) }
  scope :expired, -> { pending.where("invited_at <= ?", TOKEN_EXPIRY_DAYS.days.ago) }

  # Class Methods
  def self.find_by_token!(token)
    find_by!(token: token)
  end

  # Instance Methods
  def expired?
    pending? && invited_at <= TOKEN_EXPIRY_DAYS.days.ago
  end

  def accept!(accepting_user)
    raise I18n.t('models.judge_invitation.already_processed') unless pending?
    raise I18n.t('models.judge_invitation.expired') if expired?

    transaction do
      update!(
        status: :accepted,
        user: accepting_user,
        responded_at: Time.current
      )

      ContestJudge.create!(
        contest: contest,
        user: accepting_user,
        invited_at: invited_at
      )
    end
  end

  def decline!
    raise I18n.t('models.judge_invitation.already_processed') unless pending?

    update!(
      status: :declined,
      responded_at: Time.current
    )
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_invited_at
    self.invited_at ||= Time.current
  end

  def email_not_already_judge
    return unless contest && email.present?

    existing_judge = contest.judges.find_by(email: email)
    if existing_judge
      errors.add(:email, :already_a_judge)
    end
  end
end
