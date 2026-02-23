# frozen_string_literal: true

class MilestoneService
  def initialize(user)
    @user = user
  end

  # アクションに応じたマイルストーンチェック
  def check_and_award(action, metadata = {})
    case action.to_sym
    when :vote
      check_first_vote(metadata)
    when :submit_entry
      check_first_submission(metadata)
    when :publish_contest
      check_first_contest_published(metadata)
    when :complete_contest
      check_first_contest_completed(metadata)
    when :complete_judging
      check_all_entries_judged(metadata)
    end

    # 機能レベル更新
    @user.update_feature_level!
  end

  def check_tutorial_milestone(tutorial_type)
    UserMilestone.achieve!(@user, "tutorial_completed", { tutorial_type: tutorial_type })
  end

  private

  def check_first_vote(metadata)
    return if @user.achieved_milestone?("first_vote")

    UserMilestone.achieve!(@user, "first_vote", metadata)

    # 関連機能をアンロック
    FeatureUnlockService.new(@user).unlock_for_trigger(:first_vote)

    # フィードバック通知を送信
    broadcast_achievement("first_vote")
  end

  def check_first_submission(metadata)
    return if @user.achieved_milestone?("first_submission")

    UserMilestone.achieve!(@user, "first_submission", metadata)
    broadcast_achievement("first_submission")
  end

  def check_first_contest_published(metadata)
    return if @user.achieved_milestone?("first_contest_published")

    UserMilestone.achieve!(@user, "first_contest_published", metadata)
    FeatureUnlockService.new(@user).unlock_for_trigger(:first_contest_published)
    broadcast_achievement("first_contest_published")
  end

  def check_first_contest_completed(metadata)
    return if @user.achieved_milestone?("first_contest_completed")

    UserMilestone.achieve!(@user, "first_contest_completed", metadata)
    FeatureUnlockService.new(@user).unlock_for_trigger(:first_contest_completed)
    broadcast_achievement("first_contest_completed")
  end

  def check_all_entries_judged(metadata)
    return if @user.achieved_milestone?("all_entries_judged")

    UserMilestone.achieve!(@user, "all_entries_judged", metadata)
    broadcast_achievement("all_entries_judged")
  end

  def broadcast_achievement(milestone_type)
    badge = UserMilestone::BADGES[milestone_type]
    return unless badge

    Turbo::StreamsChannel.broadcast_append_to(
      "user_#{@user.id}_notifications",
      target: "milestone-notifications",
      partial: "tutorials/milestone_notification",
      locals: { badge: badge }
    )
  rescue StandardError => e
    Rails.logger.warn "[MilestoneService] Failed to broadcast achievement: #{e.message}"
  end
end
