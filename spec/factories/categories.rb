# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "カテゴリ#{n}" }
    description { "カテゴリの説明文" }
    sequence(:position) { |n| n }
  end
end
