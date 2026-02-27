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
end
