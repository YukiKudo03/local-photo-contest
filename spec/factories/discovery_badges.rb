# frozen_string_literal: true

FactoryBot.define do
  factory :discovery_badge do
    association :user
    association :contest
    badge_type { :pioneer }
    earned_at { Time.current }

    trait :pioneer do
      badge_type { :pioneer }
    end

    trait :explorer do
      badge_type { :explorer }
    end

    trait :curator do
      badge_type { :curator }
    end

    trait :master do
      badge_type { :master }
    end
  end
end
