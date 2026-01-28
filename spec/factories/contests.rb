# frozen_string_literal: true

FactoryBot.define do
  factory :contest do
    association :user, :organizer, :confirmed
    sequence(:title) { |n| "テストコンテスト#{n}" }
    description { "テストコンテストの説明文です。" }
    theme { "テストテーマ" }
    status { :draft }

    trait :draft do
      status { :draft }
    end

    trait :published do
      status { :published }
    end

    trait :finished do
      status { :finished }
    end

    trait :with_entry_period do
      entry_start_at { 1.day.from_now }
      entry_end_at { 1.month.from_now }
    end

    trait :accepting_entries do
      status { :published }
      entry_start_at { 1.day.ago }
      entry_end_at { 1.month.from_now }
    end

    trait :entry_ended do
      status { :published }
      entry_start_at { 2.months.ago }
      entry_end_at { 1.month.ago }
    end

    trait :deleted do
      deleted_at { Time.current }
    end
  end
end
