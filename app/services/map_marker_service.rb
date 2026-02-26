# frozen_string_literal: true

class MapMarkerService
  include Rails.application.routes.url_helpers

  def initialize(current_user: nil, url_helpers: nil)
    @current_user = current_user
    @url_helpers = url_helpers
  end

  def entry_marker_data(entry)
    {
      id: entry.id,
      title: entry.title.presence || "無題",
      lat: entry.spot.latitude.to_f,
      lng: entry.spot.longitude.to_f,
      spot_name: entry.spot.name,
      spot_id: entry.spot_id,
      contest_title: entry.contest.title,
      votes_count: entry.votes.size,
      user_name: entry.user.display_name,
      photo_url: photo_url(entry),
      entry_url: entry_path(entry),
      discovery_status: entry.spot.discovery_status,
      discovered_by_current_user: @current_user && entry.spot.discovered_by_id == @current_user.id
    }
  end

  def entries_to_markers(entries)
    entries.map { |entry| entry_marker_data(entry) }
  end

  private

  def photo_url(entry)
    return nil unless entry.photo.attached?

    if @url_helpers
      @url_helpers.url_for(entry.photo.variant(resize_to_fill: [ 150, 150 ]))
    else
      Rails.application.routes.url_helpers.rails_blob_path(
        entry.photo.variant(resize_to_fill: [ 150, 150 ]),
        only_path: true
      )
    end
  end

  def default_url_options
    { only_path: true }
  end
end
