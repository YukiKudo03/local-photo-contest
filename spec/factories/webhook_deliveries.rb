# frozen_string_literal: true

FactoryBot.define do
  factory :webhook_delivery do
    association :webhook
    event_type { "entry.created" }
    status { "pending" }
    request_body { '{"event":"entry.created"}' }
    retry_count { 0 }

    trait :delivered do
      status { "delivered" }
      status_code { 200 }
      delivered_at { Time.current }
      response_body { '{"ok":true}' }
    end

    trait :failed do
      status { "failed" }
      status_code { 500 }
      response_body { "Internal Server Error" }
    end
  end
end
