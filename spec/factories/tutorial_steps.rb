FactoryBot.define do
  factory :tutorial_step do
    sequence(:step_id) { |n| "step_#{n}" }
    sequence(:position) { |n| n }
    tutorial_type { "organizer_onboarding" }
    title { "チュートリアルステップ" }
    description { "このステップの説明です。" }
    target_selector { nil }
    target_path { nil }
    tooltip_position { "bottom" }
    options { {} }

    trait :participant do
      tutorial_type { "participant_onboarding" }
    end

    trait :organizer do
      tutorial_type { "organizer_onboarding" }
    end

    trait :admin do
      tutorial_type { "admin_onboarding" }
    end

    trait :judge do
      tutorial_type { "judge_onboarding" }
    end

    trait :with_target do
      target_selector { "[data-tutorial='target']" }
    end

    trait :centered do
      tooltip_position { "center" }
    end
  end
end
