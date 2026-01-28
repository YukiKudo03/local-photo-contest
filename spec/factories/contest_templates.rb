# frozen_string_literal: true

FactoryBot.define do
  factory :contest_template do
    user { association :user, :organizer, :confirmed }
    sequence(:name) { |n| "テンプレート #{n}" }
    theme { "テスト用テーマ" }
    description { "テスト用説明文" }
    judging_method { :vote_only }
    prize_count { 3 }
    moderation_enabled { true }
    moderation_threshold { 60.0 }
    require_spot { false }

    trait :with_source_contest do
      source_contest { association :contest, user: user }
    end

    trait :with_category do
      category
    end

    trait :with_area do
      area { association :area, user: user }
    end

    trait :judge_only do
      judging_method { :judge_only }
    end

    trait :hybrid do
      judging_method { :hybrid }
      judge_weight { 70 }
    end
  end
end
