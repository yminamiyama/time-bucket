module Api
  module V1
    class TimeBucketTemplatesController < ApplicationController
      before_action :authenticate_user!

      # POST /api/v1/time_buckets/templates
      def create
        generator = TimeBucketTemplateGenerator.new(
          user: current_user,
          granularity: params[:granularity]
        )

        if generator.generate
          buckets = current_user.time_buckets.ordered
          render json: {
            message: 'Time buckets generated successfully',
            count: buckets.count,
            buckets: buckets
          }, status: :created
        else
          render json: {
            errors: generator.errors
          }, status: :unprocessable_entity
        end
      end
    end
  end
end
