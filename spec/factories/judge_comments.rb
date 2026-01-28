# frozen_string_literal: true

FactoryBot.define do
  factory :judge_comment do
    association :contest_judge
    association :entry
    comment { "素晴らしい作品です。構図が特に印象的でした。" }
  end
end
