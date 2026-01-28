# frozen_string_literal: true

FactoryBot.define do
  factory :judge_evaluation do
    association :contest_judge
    association :entry
    association :evaluation_criterion
    score { 7 }

    trait :high_score do
      score { 10 }
    end

    trait :low_score do
      score { 1 }
    end
  end
end
