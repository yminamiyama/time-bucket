module Api
  module V1
    class NotificationSettingsController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/notification-settings
      def show
        settings = current_user.notification_preference || current_user.build_notification_preference
        
        render json: notification_response(settings)
      end

      # PATCH /api/v1/notification-settings
      def update
        settings = current_user.notification_preference || current_user.build_notification_preference
        
        if settings.update(notification_params)
          render json: notification_response(settings)
        else
          render json: { errors: settings.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def notification_params
        params.permit(:email_enabled, :slack_webhook_url, :digest_time, events: {})
      end

      def notification_response(settings)
        {
          email_enabled: settings.email_enabled,
          slack_webhook_url: settings.slack_webhook_url,
          digest_time: settings.digest_time,
          events: settings.events || {}
        }
      end
    end
  end
end
