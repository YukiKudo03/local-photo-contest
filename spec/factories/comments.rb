# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    association :user, factory: [ :user, :confirmed ]
    association :entry
    body { "素敵な写真ですね！" }
  end
end
