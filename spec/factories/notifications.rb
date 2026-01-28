# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    association :user, factory: [ :user, :confirmed ]
    association :notifiable, factory: [ :contest, :finished ]
    notification_type { Notification::TYPES[:results_announced] }
    title { "テスト通知" }
    body { "通知の内容です" }
    read_at { nil }

    trait :read do
      read_at { 1.hour.ago }
    end

    trait :results_announced do
      notification_type { Notification::TYPES[:results_announced] }
      title { "コンテストの結果が発表されました" }
    end

    trait :entry_ranked do
      association :notifiable, factory: :entry
      notification_type { Notification::TYPES[:entry_ranked] }
      title { "あなたの作品が入賞しました！" }
    end
  end
end
