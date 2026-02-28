# frozen_string_literal: true

class WebhookDelivery < ApplicationRecord
  belongs_to :webhook

  validates :event_type, presence: true
  validates :status, presence: true

  def mark_delivered!(code, body)
    update!(
      status: "delivered",
      status_code: code,
      response_body: body,
      delivered_at: Time.current
    )
  end

  def mark_failed!(code, body)
    update!(
      status: "failed",
      status_code: code,
      response_body: body,
      retry_count: retry_count + 1
    )
  end
end
