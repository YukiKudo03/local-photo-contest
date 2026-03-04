# frozen_string_literal: true

class ReactionService
  def initialize(user)
    @user = user
  end

  def toggle_like(entry)
    existing = @user.reactions.find_by(entry: entry, reaction_type: "like")
    if existing
      existing.destroy!
      { success: true, liked: false, count: entry.reload.reactions_count }
    else
      reaction = Reaction.create!(user: @user, entry: entry, reaction_type: "like")
      PointService.new(@user).award_for_action("like", source: reaction)
      MilestoneService.new(entry.user).check_and_award(:receive_like, { entry_id: entry.id })
      { success: true, liked: true, count: entry.reload.reactions_count }
    end
  rescue ActiveRecord::RecordNotUnique
    { success: true, liked: true, count: entry.reactions_count }
  end
end
