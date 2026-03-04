# frozen_string_literal: true

FactoryBot.define do
  factory :reaction do
    association :user, factory: [ :user, :confirmed ]
    association :entry
    reaction_type { "like" }
  end
end
