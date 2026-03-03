# frozen_string_literal: true

class PointService
  def initialize(user)
    @user = user
  end

  def award_for_action(action_type, source: nil, metadata: {})
    return if source && already_awarded?(action_type, source)

    points = UserPoint::POINT_VALUES[action_type]
    return unless points

    UserPoint.create!(
      user: @user,
      points: points,
      action_type: action_type,
      source_type: source&.class&.name,
      source_id: source&.id,
      metadata: metadata,
      earned_at: Time.current
    )

    update_total_points!(points)
    check_level_up!
  end

  def award_for_prize(ranking)
    action_type = case ranking.rank
    when 1 then "prize_1st"
    when 2 then "prize_2nd"
    when 3 then "prize_3rd"
    else "prize_other"
    end

    award_for_action(action_type, source: ranking)
  end

  def recalculate_total!
    total = @user.user_points.sum(:points)
    @user.update!(total_points: total)
    check_level_up!
  end

  private

  def already_awarded?(action_type, source)
    @user.user_points.exists?(
      action_type: action_type,
      source_type: source.class.name,
      source_id: source.id
    )
  end

  def update_total_points!(points_earned)
    @user.increment!(:total_points, points_earned)
  end

  def check_level_up!
    new_level = LevelCalculator.level_for(@user.total_points)
    if new_level > @user.level
      @user.update!(level: new_level)
      broadcast_level_up(new_level)
    end
  end

  def broadcast_level_up(new_level)
    Turbo::StreamsChannel.broadcast_append_to(
      "user_#{@user.id}_notifications",
      target: "milestone-notifications",
      partial: "gamification/level_up_notification",
      locals: { level: new_level, user: @user }
    )
  rescue StandardError => e
    Rails.logger.warn "[PointService] Failed to broadcast level up: #{e.message}"
  end
end
