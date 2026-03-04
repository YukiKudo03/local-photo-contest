# frozen_string_literal: true

FactoryBot.define do
  factory :entry_tag do
    association :entry
    association :tag
    confidence { 95.0 }
  end
end
