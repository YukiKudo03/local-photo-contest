# frozen_string_literal: true

class UserDataExportJob < ApplicationJob
  queue_as :default

  def perform(export_request_id)
    export_request = DataExportRequest.find(export_request_id)
    export_request.update!(status: :processing)

    service = UserDataExportService.new(export_request.user)
    zip_file = service.generate_zip

    export_request.file.attach(
      io: File.open(zip_file.path),
      filename: "data_export_#{export_request.user_id}_#{Time.current.strftime('%Y%m%d')}.zip",
      content_type: "application/zip"
    )

    export_request.update!(
      status: :completed,
      completed_at: Time.current,
      expires_at: 7.days.from_now
    )

    DataExportMailer.export_ready(export_request).deliver_later
  ensure
    zip_file&.close
    zip_file&.unlink
  end
end
