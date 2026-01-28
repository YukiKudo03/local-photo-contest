# frozen_string_literal: true

FactoryBot.define do
  factory :contest_ranking do
    association :contest, :published
    association :entry
    sequence(:rank) { |n| n }
    total_score { rand(0.0..100.0).round(4) }
    judge_score { rand(0.0..100.0).round(4) }
    vote_score { rand(0.0..100.0).round(4) }
    vote_count { rand(0..50) }
    calculated_at { Time.current }

    trait :first_place do
      rank { 1 }
      total_score { 95.0 }
    end

    trait :second_place do
      rank { 2 }
      total_score { 85.0 }
    end

    trait :third_place do
      rank { 3 }
      total_score { 75.0 }
    end
  end
end
