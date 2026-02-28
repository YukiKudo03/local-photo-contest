# frozen_string_literal: true

class WebhookDeliveryJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(delivery_id)
    delivery = WebhookDelivery.find(delivery_id)
    webhook = delivery.webhook

    payload = delivery.request_body.to_s
    signature = webhook.compute_signature(payload)

    uri = URI.parse(webhook.url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 10
    http.read_timeout = 10

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request["X-Webhook-Signature"] = signature
    request["User-Agent"] = "PhotoContest-Webhook/1.0"
    request.body = payload

    response = http.request(request)

    if response.code.to_i >= 200 && response.code.to_i < 300
      delivery.mark_delivered!(response.code.to_i, response.body)
      webhook.update!(failures_count: 0)
    else
      delivery.mark_failed!(response.code.to_i, response.body)
      webhook.increment!(:failures_count)
      webhook.disable_if_failing!
    end
  rescue StandardError => e
    delivery&.mark_failed!(0, e.message) if delivery&.persisted?
    webhook&.increment!(:failures_count) if webhook&.persisted?
    webhook&.disable_if_failing!
    raise
  end
end
