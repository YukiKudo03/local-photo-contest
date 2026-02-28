# frozen_string_literal: true

class WebhookDispatcher
  def self.dispatch(event_type, payload)
    webhooks = Webhook.for_event(event_type)
    return if webhooks.empty?

    payload_json = payload.to_json

    webhooks.each do |webhook|
      delivery = webhook.webhook_deliveries.create!(
        event_type: event_type,
        request_body: payload_json,
        status: "pending"
      )

      WebhookDeliveryJob.perform_later(delivery.id)
    end
  end
end
