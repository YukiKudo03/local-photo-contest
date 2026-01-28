class User < ApplicationRecord
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
  has_many :discovery_badges, dependent: :destroy
  has_one_attached :avatar

  # Role enum
  enum :role, { participant: 0, organizer: 1, admin: 2 }

  # Validations
  validates :role, presence: true
  validates :name, length: { maximum: 50 }, allow_blank: true
  validates :bio, length: { maximum: 500 }, allow_blank: true
  validate :avatar_content_type
  validate :avatar_size

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

  private

  def avatar_content_type
    return unless avatar.attached?
    unless avatar.content_type.in?(%w[image/jpeg image/png image/gif])
      errors.add(:avatar, "はJPEG、PNG、GIF形式のみ対応しています")
    end
  end

  def avatar_size
    return unless avatar.attached?
    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, "は5MB以下にしてください")
    end
  end
end
