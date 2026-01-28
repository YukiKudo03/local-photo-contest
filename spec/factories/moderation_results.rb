# frozen_string_literal: true

FactoryBot.define do
  factory :moderation_result do
    association :entry
    provider { "rekognition" }
    status { :pending }
    labels { nil }
    max_confidence { nil }
    raw_response { nil }

    trait :pending do
      status { :pending }
    end

    trait :approved do
      status { :approved }
      labels { [] }
      max_confidence { nil }
    end

    trait :rejected do
      status { :rejected }
      labels { [ { "Name" => "Explicit Nudity", "Confidence" => 95.5 } ] }
      max_confidence { 95.5 }
    end

    trait :requires_review do
      status { :requires_review }
      labels { [ { "Name" => "Suggestive", "Confidence" => 65.0 } ] }
      max_confidence { 65.0 }
    end

    trait :with_violation do
      labels { [ { "Name" => "Violence", "Confidence" => 85.0 } ] }
      max_confidence { 85.0 }
    end

    trait :reviewed do
      reviewed_at { Time.current }
      association :reviewed_by, factory: [ :user, :admin, :confirmed ]
      review_note { "確認しました" }
    end

    trait :with_raw_response do
      raw_response do
        {
          "ModerationLabels" => [
            { "Name" => "Explicit", "Confidence" => 75.5, "ParentName" => "" }
          ],
          "ModerationModelVersion" => "7.0"
        }
      end
    end
  end
end
