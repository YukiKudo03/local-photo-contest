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
      check_vote_count_milestones
    when :submit_entry
      check_first_submission(metadata)
      check_consecutive_participation
    when :comment
      check_comment_count_milestones
    when :win_prize
      check_prize_count_milestones
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

  def check_vote_count_milestones
    vote_count = @user.votes.count
    award_if_threshold("votes_10", vote_count, 10)
    award_if_threshold("votes_50", vote_count, 50)
  end

  def check_comment_count_milestones
    comment_count = @user.comments.count
    award_if_threshold("comments_10", comment_count, 10)
    award_if_threshold("comments_50", comment_count, 50)
  end

  def check_prize_count_milestones
    prize_count = ContestRanking.joins(:entry)
                                .where(entries: { user_id: @user.id })
                                .select(&:prize?)
                                .count
    award_if_threshold("prize_bronze", prize_count, 1)
    award_if_threshold("prize_silver", prize_count, 3)
    award_if_threshold("prize_gold", prize_count, 5)
  end

  def check_consecutive_participation
    finished_contests = Contest.where(status: :finished).order(created_at: :asc).pluck(:id)
    participated_ids = @user.entries.where(contest_id: finished_contests).pluck(:contest_id).to_set

    max_streak = 0
    current_streak = 0
    finished_contests.each do |contest_id|
      if participated_ids.include?(contest_id)
        current_streak += 1
        max_streak = [ max_streak, current_streak ].max
      else
        current_streak = 0
      end
    end

    award_if_threshold("consecutive_3_contests", max_streak, 3)
    award_if_threshold("consecutive_5_contests", max_streak, 5)
    award_if_threshold("consecutive_10_contests", max_streak, 10)
  end

  def award_if_threshold(milestone_type, current_count, threshold)
    return if current_count < threshold
    return if @user.achieved_milestone?(milestone_type)

    UserMilestone.achieve!(@user, milestone_type, { count: current_count })
    broadcast_achievement(milestone_type)
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
