# frozen_string_literal: true

FactoryBot.define do
  factory :contest_judge do
    association :contest, :published
    association :user, :confirmed
    invited_at { Time.current }
  end
end
