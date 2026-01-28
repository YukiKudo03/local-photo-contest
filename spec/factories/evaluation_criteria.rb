# frozen_string_literal: true

FactoryBot.define do
  factory :evaluation_criterion do
    association :contest, :published
    sequence(:name) { |n| "評価基準#{n}" }
    description { "評価基準の説明" }
    sequence(:position) { |n| n }
    max_score { 10 }
  end
end
