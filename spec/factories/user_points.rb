# frozen_string_literal: true

FactoryBot.define do
  factory :user_point do
    association :user, :confirmed
    points { 10 }
    action_type { "submit_entry" }
    earned_at { Time.current }
  end
end
