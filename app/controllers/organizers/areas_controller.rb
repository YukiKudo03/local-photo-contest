# frozen_string_literal: true

module Organizers
  class AreasController < BaseController
    before_action :set_area, only: [ :show, :edit, :update, :destroy ]
    before_action :authorize_area!, only: [ :show, :edit, :update, :destroy ]

    def index
      @areas = current_user.areas.ordered
    end

    def show
    end

    def new
      @area = current_user.areas.build
    end

    def create
      @area = current_user.areas.build(area_params)

      if @area.save
        redirect_to organizers_area_path(@area), notice: "エリアを作成しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @area.update(area_params)
        redirect_to organizers_area_path(@area), notice: "エリアを更新しました。"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @area.contests.exists?
        redirect_to organizers_area_path(@area), alert: "このエリアに関連するコンテストがあるため削除できません。"
        return
      end

      @area.destroy
      redirect_to organizers_areas_path, notice: "エリアを削除しました。"
    end

    private

    def set_area
      @area = Area.find(params[:id])
    end

    def authorize_area!
      return if @area.owned_by?(current_user)

      redirect_to organizers_areas_path, alert: "この操作を行う権限がありません。"
    end

    def area_params
      params.require(:area).permit(
        :name,
        :prefecture,
        :city,
        :address,
        :latitude,
        :longitude,
        :boundary_geojson,
        :description,
        :position
      )
    end
  end
end
