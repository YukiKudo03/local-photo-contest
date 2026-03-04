# frozen_string_literal: true

FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "tag_#{n}" }
    category { "general" }

    trait :scene do
      category { "scene" }
      name { "landscape" }
      name_ja { "風景" }
    end

    trait :object do
      category { "object" }
      name { "flower" }
      name_ja { "花" }
    end

    trait :activity do
      category { "activity" }
      name { "walking" }
      name_ja { "ウォーキング" }
    end
  end
end
