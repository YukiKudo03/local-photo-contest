# frozen_string_literal: true

module Gallery
  class MapsController < ApplicationController
    def show
      @entries_with_location = map_entries_with_coordinates
      @entries_without_location = map_entries_without_coordinates

      # For filter dropdowns
      @contests = Contest.where(status: [ :published, :finished ]).active.order(created_at: :desc)
      @areas = Area.ordered
    end

    def data
      entries = base_entries
                  .joins(spot: {})
                  .where.not(spots: { latitude: nil, longitude: nil })

      entries = EntryFilterService.new(entries, params).filter

      entries = entries.includes(:spot, :user, :contest, :votes, photo_attachment: :blob)
                       .limit(500)

      render json: map_marker_service.entries_to_markers(entries)
    end

    private

    def map_marker_service
      @map_marker_service ||= MapMarkerService.new(current_user: current_user, url_helpers: self)
    end

    def base_entries
      Entry.visible
           .joins(:contest)
           .where(contests: { status: [ :published, :finished ], deleted_at: nil })
    end

    def map_entries_with_coordinates
      base_entries
        .joins(spot: {})
        .where.not(spots: { latitude: nil, longitude: nil })
        .includes(:spot, :user, :contest, :votes, photo_attachment: :blob)
        .limit(500)
    end

    def map_entries_without_coordinates
      base_entries
        .left_joins(:spot)
        .where("spots.latitude IS NULL OR spots.longitude IS NULL OR entries.spot_id IS NULL")
        .includes(:user, :contest, :area, :votes, photo_attachment: :blob)
        .order(created_at: :desc)
        .limit(50)
    end
  end
end
