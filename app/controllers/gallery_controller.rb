# frozen_string_literal: true

class GalleryController < ApplicationController
  def index
    @entries = base_entries

    # Filter by contest
    if params[:contest_id].present?
      @entries = @entries.where(contest_id: params[:contest_id])
    end

    # Filter by category (through contest)
    if params[:category_id].present?
      @entries = @entries.where(contests: { category_id: params[:category_id] })
    end

    # Filter by area
    if params[:area_id].present?
      @entries = @entries.where(area_id: params[:area_id])
    end

    # Sort
    @entries = case params[:sort]
    when "popular"
                 @entries.left_joins(:votes)
                         .group("entries.id")
                         .order(Arel.sql("COUNT(votes.id) DESC"), "entries.created_at DESC")
    when "oldest"
                 @entries.order(created_at: :asc)
    else # newest (default)
                 @entries.order(created_at: :desc)
    end

    @entries = @entries.includes(:user, :contest, :area, :votes, photo_attachment: :blob)
                       .page(params[:page]).per(24)

    # For filter dropdowns (only needed for full page requests)
    unless turbo_frame_request?
      @contests = Contest.where(status: [ :published, :finished ]).active.order(created_at: :desc)
      @categories = Category.ordered
      @areas = Area.ordered
    end

    # Respond with just the entries partial for Turbo Frame requests
    if turbo_frame_request?
      render partial: "gallery/entries", layout: false
    end
  end

  def map
    @entries_with_location = map_entries_with_coordinates
    @entries_without_location = map_entries_without_coordinates

    # For filter dropdowns
    @contests = Contest.where(status: [ :published, :finished ]).active.order(created_at: :desc)
    @areas = Area.ordered
  end

  # API endpoint for map markers
  def map_data
    entries = base_entries
                .joins(spot: {})
                .where.not(spots: { latitude: nil, longitude: nil })

    # Apply filters
    entries = entries.where(contest_id: params[:contest_id]) if params[:contest_id].present?
    entries = entries.where(area_id: params[:area_id]) if params[:area_id].present?
    entries = entries.where(spot_id: params[:spot_id]) if params[:spot_id].present?

    # Filter by discovery status
    if params[:discovery_status].present?
      case params[:discovery_status]
      when "discovered"
        entries = entries.where(spots: { discovery_status: :discovered })
      when "certified"
        entries = entries.where(spots: { discovery_status: :certified })
      when "organizer"
        entries = entries.where(spots: { discovery_status: :organizer_created })
      end
    end

    entries = entries.includes(:spot, :user, :contest, :votes, photo_attachment: :blob)
                     .limit(500)

    render json: entries.map { |entry| entry_marker_data(entry) }
  end

  private

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
      photo_url: entry.photo.attached? ? url_for(entry.photo.variant(resize_to_fill: [ 150, 150 ])) : nil,
      entry_url: entry_path(entry),
      discovery_status: entry.spot.discovery_status,
      discovered_by_current_user: current_user && entry.spot.discovered_by_id == current_user.id
    }
  end
end
