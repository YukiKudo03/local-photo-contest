# frozen_string_literal: true

FactoryBot.define do
  factory :terms_acceptance do
    association :user
    association :terms_of_service
    accepted_at { Time.current }
    ip_address { "127.0.0.1" }
  end
end
