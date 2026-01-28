# frozen_string_literal: true

FactoryBot.define do
  factory :discovery_challenge do
    association :contest
    sequence(:name) { |n| "発掘チャレンジ#{n}" }
    description { "発掘チャレンジの説明文です" }
    theme { "テーマ" }
    status { :draft }

    trait :draft do
      status { :draft }
    end

    trait :active do
      status { :active }
      starts_at { 1.day.ago }
      ends_at { 1.week.from_now }
    end

    trait :finished do
      status { :finished }
      starts_at { 2.weeks.ago }
      ends_at { 1.week.ago }
    end

    trait :with_period do
      starts_at { 1.day.from_now }
      ends_at { 1.week.from_now }
    end

    trait :active_now do
      status { :active }
      starts_at { 1.day.ago }
      ends_at { 1.week.from_now }
    end
  end
end
