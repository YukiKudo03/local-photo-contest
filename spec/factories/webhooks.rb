# frozen_string_literal: true

FactoryBot.define do
  factory :webhook do
    association :user, :confirmed
    url { "https://example.com/webhook" }
    secret { SecureRandom.hex(32) }
    event_types { '["entry.created","vote.created"]' }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :with_contest do
      association :contest, :published
    end

    trait :failing do
      failures_count { 9 }
    end
  end
end
