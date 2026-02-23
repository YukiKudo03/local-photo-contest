FactoryBot.define do
  factory :tutorial_progress do
    user
    tutorial_type { "organizer_onboarding" }
    current_step_id { nil }
    completed { false }
    skipped { false }
    started_at { nil }
    completed_at { nil }
    step_data { {} }

    trait :started do
      started_at { Time.current }
      current_step_id { "step1" }
    end

    trait :completed do
      started_at { 1.hour.ago }
      completed { true }
      completed_at { Time.current }
    end

    trait :skipped do
      skipped { true }
      completed_at { Time.current }
    end

    trait :participant do
      tutorial_type { "participant_onboarding" }
    end

    trait :organizer do
      tutorial_type { "organizer_onboarding" }
    end

    trait :admin do
      tutorial_type { "admin_onboarding" }
    end
  end
end
