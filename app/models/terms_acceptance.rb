class TermsAcceptance < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :terms_of_service

  # Validations
  validates :accepted_at, presence: true
  validates :ip_address, presence: true
  validates :user_id, uniqueness: { scope: :terms_of_service_id, message: :already_accepted }

  # Scopes
  scope :recent, -> { order(accepted_at: :desc) }
  scope :for_terms, ->(terms) { where(terms_of_service: terms) }
end
