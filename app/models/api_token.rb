# frozen_string_literal: true

class ApiToken < ApplicationRecord
  belongs_to :user

  validates :name, presence: true, length: { maximum: 100 }
  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  scope :active, -> {
    where(revoked_at: nil)
      .where("expires_at IS NULL OR expires_at > ?", Time.current)
  }

  def active?
    revoked_at.nil? && (expires_at.nil? || expires_at > Time.current)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end

  def parsed_scopes
    case scopes
    when String then JSON.parse(scopes)
    when Array then scopes
    else [ "read" ]
    end
  rescue JSON::ParserError
    [ "read" ]
  end

  def scope?(scope_name)
    parsed_scopes.include?(scope_name.to_s)
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(48)
  end
end
