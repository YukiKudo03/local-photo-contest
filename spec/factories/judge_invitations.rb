# frozen_string_literal: true

FactoryBot.define do
  factory :judge_invitation do
    association :contest, :published
    sequence(:email) { |n| "judge#{n}@example.com" }
    token { SecureRandom.urlsafe_base64(32) }
    status { :pending }
    invited_at { Time.current }

    trait :accepted do
      status { :accepted }
      responded_at { Time.current }
      association :user, :confirmed
    end

    trait :declined do
      status { :declined }
      responded_at { Time.current }
    end

    trait :expired do
      invited_at { 31.days.ago }
    end
  end
end
