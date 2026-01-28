# frozen_string_literal: true

module Organizers
  class DiscoverySpotsController < BaseController
    before_action :set_contest
    before_action :authorize_contest!
    before_action :set_spot, only: [ :certify, :reject ]

    def index
      @pending_spots = @contest.spots
                               .pending_certification
                               .includes(:discovered_by, :entries)
                               .order(created_at: :desc)
      @pending_count = @pending_spots.count

      @certified_spots = @contest.spots
                                 .discovery_certified
                                 .includes(:discovered_by, :certified_by)
                                 .order(certified_at: :desc)
                                 .limit(10)

      @rejected_spots = @contest.spots
                                .discovery_rejected
                                .includes(:discovered_by, :certified_by)
                                .order(certified_at: :desc)
                                .limit(10)
    end

    def certify
      DiscoverySpotService.certify_spot(spot: @spot, user: current_user)

      respond_to do |format|
        format.html { redirect_to organizers_contest_discovery_spots_path(@contest), notice: "「#{@spot.name}」を認定しました。" }
        format.turbo_stream
      end
    rescue ArgumentError => e
      respond_to do |format|
        format.html { redirect_to organizers_contest_discovery_spots_path(@contest), alert: e.message }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: e.message }) }
      end
    end

    def reject
      reason = params[:reason].presence || params.dig(:spot, :rejection_reason)

      if reason.blank?
        respond_to do |format|
          format.html { redirect_to organizers_contest_discovery_spots_path(@contest), alert: "却下理由を入力してください。" }
          format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: "却下理由を入力してください。" }) }
        end
        return
      end

      DiscoverySpotService.reject_spot(spot: @spot, user: current_user, reason: reason)

      respond_to do |format|
        format.html { redirect_to organizers_contest_discovery_spots_path(@contest), notice: "「#{@spot.name}」を却下しました。" }
        format.turbo_stream
      end
    rescue ArgumentError => e
      respond_to do |format|
        format.html { redirect_to organizers_contest_discovery_spots_path(@contest), alert: e.message }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { alert: e.message }) }
      end
    end

    def merge
      target_id = params[:target_id]
      source_ids = params[:source_ids]

      if target_id.blank? || source_ids.blank?
        redirect_to organizers_contest_discovery_spots_path(@contest), alert: "統合先と統合元を選択してください。"
        return
      end

      target = @contest.spots.find(target_id)
      sources = @contest.spots.where(id: source_ids).where.not(id: target_id)

      if sources.empty?
        redirect_to organizers_contest_discovery_spots_path(@contest), alert: "統合元のスポットを選択してください。"
        return
      end

      DiscoverySpotService.merge_spots(target: target, sources: sources)

      redirect_to organizers_contest_discovery_spots_path(@contest), notice: "#{sources.count}件のスポットを「#{target.name}」に統合しました。"
    rescue ActiveRecord::RecordNotFound
      redirect_to organizers_contest_discovery_spots_path(@contest), alert: "指定されたスポットが見つかりません。"
    end

    private

    def set_contest
      @contest = Contest.active.find(params[:contest_id])
    end

    def authorize_contest!
      return if @contest.owned_by?(current_user)

      redirect_to organizers_contests_path, alert: "この操作を行う権限がありません。"
    end

    def set_spot
      @spot = @contest.spots.find(params[:id])
    end
  end
end
