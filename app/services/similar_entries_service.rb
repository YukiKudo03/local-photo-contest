# frozen_string_literal: true

class SimilarEntriesService
  def initialize(entry, limit: 6)
    @entry = entry
    @limit = limit
  end

  def find
    candidates = []
    candidates.concat(same_camera_entries)
    candidates.concat(same_contest_entries)
    candidates.concat(same_user_entries)

    candidates
      .uniq(&:id)
      .reject { |e| e.id == @entry.id }
      .first(@limit)
  end

  private

  def same_camera_entries
    model = @entry.exif_data&.dig("Model")
    return [] unless model.present?

    base_scope
      .where("json_extract(entries.exif_data, '$.Model') = ?", model)
      .order(created_at: :desc)
      .limit(@limit)
      .to_a
  end

  def same_contest_entries
    base_scope
      .where(contest_id: @entry.contest_id)
      .order(created_at: :desc)
      .limit(@limit)
      .to_a
  end

  def same_user_entries
    base_scope
      .where(user_id: @entry.user_id)
      .order(created_at: :desc)
      .limit(@limit)
      .to_a
  end

  def base_scope
    Entry.visible
         .joins(:contest)
         .where(contests: { status: [ :published, :finished ], deleted_at: nil })
         .where.not(id: @entry.id)
  end
end
