# frozen_string_literal: true

class FeatureUnlockService
  def initialize(user)
    @user = user
  end

  def unlock_for_trigger(trigger)
    features_to_unlock = FeatureUnlock::UNLOCK_TRIGGERS.select { |_, t| t == trigger }.keys

    features_to_unlock.each do |feature_key|
      FeatureUnlock.unlock!(@user, feature_key, trigger.to_s)
    end

    broadcast_unlocks(features_to_unlock) if features_to_unlock.any?
  end

  def unlock_feature(feature_key, trigger = nil)
    FeatureUnlock.unlock!(@user, feature_key, trigger)
  end

  def unlocked?(feature_key)
    @user.feature_unlocks.exists?(feature_key: feature_key)
  end

  def all_unlocked_features
    @user.feature_unlocks.pluck(:feature_key)
  end

  private

  def broadcast_unlocks(feature_keys)
    Turbo::StreamsChannel.broadcast_append_to(
      "user_#{@user.id}_notifications",
      target: "feature-unlocks",
      partial: "tutorials/feature_unlock_notification",
      locals: { features: feature_keys }
    )
  rescue StandardError => e
    Rails.logger.warn "[FeatureUnlockService] Failed to broadcast unlocks: #{e.message}"
  end
end
