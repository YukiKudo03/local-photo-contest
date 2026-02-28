# frozen_string_literal: true

module Api
  module V1
    class WebhooksController < BaseController
      before_action :require_write_scope!, only: [ :create, :update, :destroy ]
      before_action :set_webhook, only: [ :show, :update, :destroy, :deliveries ]

      def index
        @webhooks = current_user.webhooks.order(created_at: :desc)
        render json: { data: @webhooks.map { |w| webhook_json(w) } }
      end

      def show
        render json: { data: webhook_json(@webhook) }
      end

      def create
        @webhook = current_user.webhooks.build(webhook_params)

        if @webhook.save
          render json: { data: webhook_json(@webhook) }, status: :created
        else
          render json: {
            error: {
              code: "unprocessable_entity",
              message: @webhook.errors.full_messages.join(", "),
              details: @webhook.errors.messages
            }
          }, status: :unprocessable_entity
        end
      end

      def update
        if @webhook.update(webhook_params)
          render json: { data: webhook_json(@webhook) }
        else
          render json: {
            error: {
              code: "unprocessable_entity",
              message: @webhook.errors.full_messages.join(", "),
              details: @webhook.errors.messages
            }
          }, status: :unprocessable_entity
        end
      end

      def destroy
        @webhook.destroy!
        head :no_content
      end

      def deliveries
        deliveries = @webhook.webhook_deliveries.order(created_at: :desc)
        render json: {
          data: deliveries.map { |d|
            {
              id: d.id,
              event_type: d.event_type,
              status: d.status,
              status_code: d.status_code,
              retry_count: d.retry_count,
              delivered_at: d.delivered_at&.iso8601,
              created_at: d.created_at.iso8601
            }
          }
        }
      end

      private

      def require_write_scope!
        require_scope!("write")
        return if performed?
      end

      def set_webhook
        @webhook = current_user.webhooks.find(params[:id])
      end

      def webhook_params
        params.require(:webhook).permit(:url, :contest_id, :active, event_types: [])
      end

      def webhook_json(webhook)
        {
          id: webhook.id,
          url: webhook.url,
          event_types: webhook.parsed_event_types,
          active: webhook.active,
          failures_count: webhook.failures_count,
          contest_id: webhook.contest_id,
          secret: webhook.secret,
          created_at: webhook.created_at.iso8601,
          updated_at: webhook.updated_at.iso8601
        }
      end
    end
  end
end
