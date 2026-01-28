class TermsOfService < ApplicationRecord
  # Associations
  has_many :terms_acceptances, dependent: :restrict_with_error

  # Validations
  validates :version, presence: true, uniqueness: true
  validates :content, presence: true
  validates :published_at, presence: true

  # Scopes
  scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current) }
  scope :by_version, ->(version) { where(version: version) }

  # Get the current (latest published) terms
  def self.current
    published.order(published_at: :desc).first
  end
end
