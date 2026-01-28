# frozen_string_literal: true

class ContestsController < ApplicationController
  def index
    @contests = Contest.where(status: [ :published, :finished ])
                       .active
                       .includes(thumbnail_attachment: :blob)
                       .recent
  end

  def show
    @contest = Contest.where(status: [ :published, :finished ]).active.find(params[:id])
  end
end
