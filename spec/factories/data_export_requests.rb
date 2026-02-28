# frozen_string_literal: true

FactoryBot.define do
  factory :data_export_request do
    association :user
    status { :pending }
    requested_at { Time.current }

    trait :processing do
      status { :processing }
    end

    trait :completed do
      status { :completed }
      completed_at { Time.current }
      expires_at { 7.days.from_now }
    end

    trait :expired do
      status { :expired }
      completed_at { 10.days.ago }
      expires_at { 3.days.ago }
    end
  end
end
