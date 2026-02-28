# frozen_string_literal: true

FactoryBot.define do
  factory :api_token do
    association :user, :confirmed
    sequence(:name) { |n| "API Token #{n}" }
    expires_at { 1.year.from_now }

    trait :revoked do
      revoked_at { Time.current }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :with_write_scope do
      scopes { '["read","write"]' }
    end
  end
end
