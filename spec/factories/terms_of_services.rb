# frozen_string_literal: true

FactoryBot.define do
  factory :terms_of_service do
    sequence(:version) { |n| "#{n}.0" }
    content { "これは利用規約のサンプルテキストです。\n\n第1条（目的）\n本規約は、本サービスの利用条件を定めます。\n\n第2条（禁止事項）\n以下の行為を禁止します。\n- 法令に違反する行為\n- 他者の権利を侵害する行為" }
    published_at { Time.current }

    trait :current do
      # Default is already current (published_at is Time.current)
    end

    trait :future do
      published_at { 1.day.from_now }
    end

    trait :old do
      published_at { 1.year.ago }
    end
  end
end
