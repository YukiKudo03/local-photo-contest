# frozen_string_literal: true

FactoryBot.define do
  factory :vote do
    association :user, :confirmed
    entry

    trait :for_other_user_entry do
      after(:build) do |vote|
        # Ensure the voter is different from the entry owner
        vote.user = create(:user, :confirmed) if vote.user == vote.entry.user
      end
    end
  end
end
