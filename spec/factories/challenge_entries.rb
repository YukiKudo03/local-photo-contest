# frozen_string_literal: true

FactoryBot.define do
  factory :challenge_entry do
    association :discovery_challenge
    association :entry
  end
end
