# frozen_string_literal: true

FactoryBot.define do
  factory :spot_vote do
    association :user
    association :spot

    trait :for_certified_spot do
      association :spot, factory: [:spot, :certified]
    end
  end
end
