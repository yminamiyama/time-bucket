module Api
  module V1
    class TimeBucketsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_time_bucket, only: [:show, :update, :destroy]

      # GET /api/v1/time_buckets
      def index
        @time_buckets = current_user.time_buckets.ordered
        render json: @time_buckets
      end

      # GET /api/v1/time_buckets/:id
      def show
        render json: @time_bucket
      end

      # POST /api/v1/time_buckets
      def create
        @time_bucket = current_user.time_buckets.build(time_bucket_params)

        if @time_bucket.save
          render json: @time_bucket, status: :created
        else
          render json: { errors: @time_bucket.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/time_buckets/:id
      def update
        if @time_bucket.update(time_bucket_params)
          render json: @time_bucket
        else
          render json: { errors: @time_bucket.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/time_buckets/:id
      def destroy
        @time_bucket.destroy
        head :no_content
      end

      private

      def set_time_bucket
        @time_bucket = current_user.time_buckets.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Time bucket not found' }, status: :not_found
      end

      def time_bucket_params
        params.require(:time_bucket).permit(
          :label,
          :description,
          :start_age,
          :end_age,
          :granularity,
          :position
        )
      end
    end
  end
end
