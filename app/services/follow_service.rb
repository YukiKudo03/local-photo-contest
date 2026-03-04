# frozen_string_literal: true

class FollowService
  def initialize(follower)
    @follower = follower
  end

  def follow(target_user)
    return { success: false, error: :cannot_follow_self } if @follower.id == target_user.id
    return { success: false, error: :already_following } if @follower.following?(target_user)

    follow = Follow.create!(follower: @follower, followed: target_user)
    PointService.new(@follower).award_for_action("follow", source: follow)
    MilestoneService.new(@follower).check_and_award(:follow, { followed_user_id: target_user.id })
    MilestoneService.new(target_user).check_and_award(:gain_follower, { follower_user_id: @follower.id })
    { success: true, follow: follow }
  rescue ActiveRecord::RecordNotUnique
    { success: false, error: :already_following }
  end

  def unfollow(target_user)
    follow = @follower.active_follows.find_by(followed: target_user)
    return { success: false, error: :not_following } unless follow

    follow.destroy!
    { success: true }
  end
end
