# frozen_string_literal: true

module Admin
  class CategoriesController < BaseController
    before_action :set_category, only: [ :show, :edit, :update, :destroy ]

    def index
      @categories = Category.order(position: :asc)
    end

    def show
      @contests = @category.contests.includes(:user).order(created_at: :desc).limit(20)
    end

    def new
      @category = Category.new
    end

    def create
      @category = Category.new(category_params)
      @category.position = Category.maximum(:position).to_i + 1

      if @category.save
        redirect_to admin_categories_path, notice: t('flash.admin.categories.created')
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @category.update(category_params)
        redirect_to admin_categories_path, notice: t('flash.admin.categories.updated')
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @category.contests.exists?
        redirect_to admin_categories_path, alert: t('flash.admin.categories.has_contests')
      else
        @category.destroy
        redirect_to admin_categories_path, notice: t('flash.admin.categories.destroyed')
      end
    end

    private

    def set_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:name, :description, :position)
    end
  end
end
