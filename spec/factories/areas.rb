# frozen_string_literal: true

FactoryBot.define do
  factory :area do
    association :user, :organizer, :confirmed
    sequence(:name) { |n| "地域#{n}" }
    sequence(:position) { |n| n }
    prefecture { "東京都" }
    city { "渋谷区" }
    address { "道玄坂1-1-1" }

    trait :with_coordinates do
      latitude { 35.6580339 }
      longitude { 139.7016358 }
    end

    trait :with_boundary do
      with_coordinates
      boundary_geojson do
        {
          type: "Polygon",
          coordinates: [
            [
              [ 139.6980, 35.6550 ],
              [ 139.7050, 35.6550 ],
              [ 139.7050, 35.6610 ],
              [ 139.6980, 35.6610 ],
              [ 139.6980, 35.6550 ]
            ]
          ]
        }.to_json
      end
    end

    trait :with_description do
      description { "渋谷の商店街エリアです。" }
    end

    trait :osaka do
      prefecture { "大阪府" }
      city { "大阪市北区" }
      address { "梅田1-1-1" }
      latitude { 34.7024 }
      longitude { 135.4959 }
    end
  end
end
