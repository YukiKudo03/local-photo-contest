# frozen_string_literal: true

FactoryBot.define do
  factory :spot do
    association :contest
    sequence(:name) { |n| "スポット#{n}" }
    category { :restaurant }
    address { "東京都渋谷区道玄坂1-2-3" }
    sequence(:position) { |n| n }

    trait :with_coordinates do
      latitude { 35.6580339 }
      longitude { 139.7016358 }
    end

    trait :restaurant do
      category { :restaurant }
    end

    trait :retail do
      category { :retail }
    end

    trait :landmark do
      category { :landmark }
    end

    trait :park do
      category { :park }
    end

    trait :temple_shrine do
      category { :temple_shrine }
    end

    trait :with_description do
      description { "おすすめの撮影スポットです。" }
    end

    # Discovery status traits
    trait :organizer_created do
      discovery_status { :organizer_created }
    end

    trait :discovered do
      discovery_status { :discovered }
      association :discovered_by, factory: :user
      discovered_at { Time.current }
      discovery_comment { "素敵な場所を見つけました！" }
    end

    trait :certified do
      discovery_status { :certified }
      association :discovered_by, factory: :user
      discovered_at { 1.day.ago }
      discovery_comment { "素敵な場所を見つけました！" }
      association :certified_by, factory: :user
      certified_at { Time.current }
    end

    trait :rejected do
      discovery_status { :rejected }
      association :discovered_by, factory: :user
      discovered_at { 1.day.ago }
      discovery_comment { "素敵な場所を見つけました！" }
      association :certified_by, factory: :user
      certified_at { Time.current }
      rejection_reason { "既に登録済みのスポットです" }
    end

    trait :with_votes do
      after(:create) do |spot|
        create_list(:spot_vote, 3, spot: spot)
      end
    end
  end
end
