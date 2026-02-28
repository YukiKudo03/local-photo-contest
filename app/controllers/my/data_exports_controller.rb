# frozen_string_literal: true

class My::DataExportsController < ApplicationController
  before_action :authenticate_user!

  def create
    if DataExportRequest.rate_limited?(current_user)
      redirect_to my_profile_path, alert: t("gdpr.data_export.rate_limited")
      return
    end

    export_request = current_user.data_export_requests.create!(
      status: :pending,
      requested_at: Time.current
    )

    UserDataExportJob.perform_later(export_request.id)
    redirect_to my_data_export_path(export_request), notice: t("gdpr.data_export.requested")
  end

  def show
    @export_request = current_user.data_export_requests.find(params[:id])
  end

  def download
    @export_request = current_user.data_export_requests.find(params[:id])

    if @export_request.expired? || !@export_request.completed?
      redirect_to my_profile_path, alert: t("gdpr.data_export.expired")
      return
    end

    redirect_to rails_blob_path(@export_request.file, disposition: "attachment")
  end
end
