# frozen_string_literal: true

module Organizers
  class SpotsController < BaseController
    before_action :set_contest
    before_action :authorize_contest!
    before_action :set_spot, only: [ :edit, :update, :destroy, :merge, :do_merge ]

    def index
      @spots = @contest.spots.where(merged_into_id: nil).ordered
      @spots = @contest.spots.ordered if params[:show_merged].present?
    end

    def new
      @spot = @contest.spots.build
    end

    def create
      @spot = @contest.spots.build(spot_params)

      if @spot.save
        redirect_to organizers_contest_spots_path(@contest), notice: "スポットを登録しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @spot.update(spot_params)
        redirect_to organizers_contest_spots_path(@contest), notice: "スポットを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @spot.destroy
      redirect_to organizers_contest_spots_path(@contest), notice: "スポットを削除しました。"
    end

    def merge
      @available_spots = @contest.spots
                                 .where(merged_into_id: nil)
                                 .where.not(id: @spot.id)
                                 .ordered
      @entries_count = @spot.entries.count
      @votes_count = @spot.spot_votes.count
    end

    def do_merge
      primary_spot = @contest.spots.find(params[:primary_spot_id])
      service = SpotMergeService.new(primary_spot, @spot)
      service.merge

      redirect_to organizers_contest_spots_path(@contest),
                  notice: "スポットを統合しました（#{service.preview[:entries_to_move]}件の作品を移動）。"
    rescue SpotMergeService::MergeError => e
      redirect_to merge_organizers_contest_spot_path(@contest, @spot),
                  alert: "統合に失敗しました: #{e.message}"
    end

    def update_positions
      positions = params[:positions] || []

      ActiveRecord::Base.transaction do
        positions.each_with_index do |spot_id, index|
          @contest.spots.find(spot_id).update!(position: index + 1)
        end
      end

      head :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def set_contest
      @contest = Contest.find(params[:contest_id])
    end

    def authorize_contest!
      return if @contest.user == current_user

      redirect_to organizers_contests_path, alert: "この操作を行う権限がありません。"
    end

    def set_spot
      @spot = @contest.spots.find(params[:id])
    end

    def spot_params
      params.require(:spot).permit(
        :name,
        :category,
        :address,
        :latitude,
        :longitude,
        :description,
        :position
      )
    end
  end
end
