# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    role { :participant }

    trait :organizer do
      role { :organizer }
    end

    trait :admin do
      role { :admin }
    end

    trait :confirmed do
      confirmed_at { Time.current }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :locked do
      locked_at { Time.current }
      failed_attempts { 5 }
    end
  end
end
