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

    trait :scheduled_for_publish do
      status { :draft }
      scheduled_publish_at { 1.day.from_now }
    end

    trait :past_scheduled_publish do
      status { :draft }
      after(:create) do |contest|
        contest.update_column(:scheduled_publish_at, 1.hour.ago)
      end
    end

    trait :scheduled_for_finish do
      status { :published }
      scheduled_finish_at { 1.month.from_now }
    end

    trait :past_scheduled_finish do
      status { :published }
      scheduled_finish_at { 1.hour.ago }
    end

    trait :with_judging_deadline do
      judging_deadline_at { 2.weeks.from_now }
    end

    trait :archived do
      status { :finished }
      results_announced_at { 100.days.ago }
      archived_at { Time.current }
    end

    trait :archivable do
      status { :finished }
      results_announced_at { 100.days.ago }
      auto_archive_days { 90 }
    end
  end
end
