# frozen_string_literal: true

class EntryFilterService
  def initialize(scope, params)
    @scope = scope
    @params = params
  end

  def filter
    apply_text_search
    apply_contest_filter
    apply_category_filter
    apply_area_filter
    apply_spot_filter
    apply_discovery_status_filter
    apply_camera_make_filter
    apply_camera_model_filter
    apply_focal_length_filter
    apply_iso_filter
    @scope
  end

  private

  def apply_text_search
    return unless @params[:q].present?
    @scope = @scope.search(@params[:q].to_s.strip)
  end

  def apply_contest_filter
    return unless @params[:contest_id].present?
    @scope = @scope.where(contest_id: @params[:contest_id])
  end

  def apply_category_filter
    return unless @params[:category_id].present?
    @scope = @scope.where(contests: { category_id: @params[:category_id] })
  end

  def apply_area_filter
    return unless @params[:area_id].present?
    @scope = @scope.where(area_id: @params[:area_id])
  end

  def apply_spot_filter
    return unless @params[:spot_id].present?
    @scope = @scope.where(spot_id: @params[:spot_id])
  end

  def apply_discovery_status_filter
    return unless @params[:discovery_status].present?

    case @params[:discovery_status]
    when "discovered"
      @scope = @scope.where(spots: { discovery_status: :discovered })
    when "certified"
      @scope = @scope.where(spots: { discovery_status: :certified })
    when "organizer"
      @scope = @scope.where(spots: { discovery_status: :organizer_created })
    end
  end

  def apply_camera_make_filter
    return unless @params[:camera_make].present?
    @scope = @scope.where("json_extract(entries.exif_data, '$.Make') = ?", @params[:camera_make])
  end

  def apply_camera_model_filter
    return unless @params[:camera_model].present?
    @scope = @scope.where("json_extract(entries.exif_data, '$.Model') = ?", @params[:camera_model])
  end

  def apply_focal_length_filter
    if @params[:focal_length_min].present?
      @scope = @scope.where("CAST(json_extract(entries.exif_data, '$.FocalLength') AS REAL) >= ?", @params[:focal_length_min].to_f)
    end
    if @params[:focal_length_max].present?
      @scope = @scope.where("CAST(json_extract(entries.exif_data, '$.FocalLength') AS REAL) <= ?", @params[:focal_length_max].to_f)
    end
  end

  def apply_iso_filter
    if @params[:iso_min].present?
      @scope = @scope.where("CAST(json_extract(entries.exif_data, '$.ISOSpeedRatings') AS INTEGER) >= ?", @params[:iso_min].to_i)
    end
    if @params[:iso_max].present?
      @scope = @scope.where("CAST(json_extract(entries.exif_data, '$.ISOSpeedRatings') AS INTEGER) <= ?", @params[:iso_max].to_i)
    end
  end
end
