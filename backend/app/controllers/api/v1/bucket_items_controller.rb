module Api
  module V1
    class BucketItemsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_time_bucket, only: [:index, :create]
      before_action :set_bucket_item, only: [:show, :update, :destroy, :complete]

      # GET /api/v1/time_buckets/:time_bucket_id/bucket_items
      def index
        @bucket_items = @time_bucket.bucket_items
        render json: @bucket_items
      end

      # GET /api/v1/bucket_items/:id
      def show
        render json: @bucket_item
      end

      # POST /api/v1/time_buckets/:time_bucket_id/bucket_items
      def create
        @bucket_item = @time_bucket.bucket_items.build(bucket_item_params)

        if @bucket_item.save
          render json: @bucket_item, status: :created
        else
          render json: { errors: @bucket_item.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/bucket_items/:id
      def update
        if @bucket_item.update(bucket_item_params)
          render json: @bucket_item
        else
          render json: { errors: @bucket_item.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/bucket_items/:id/complete
      def complete
        if @bucket_item.update(status: 'done', completed_at: Time.current)
          render json: @bucket_item
        else
          render json: { errors: @bucket_item.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/bucket_items/:id
      def destroy
        @bucket_item.destroy
        head :no_content
      end

      private

      def set_time_bucket
        @time_bucket = current_user.time_buckets.find(params[:time_bucket_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Time bucket not found' }, status: :not_found
      end

      def set_bucket_item
        @bucket_item = BucketItem.joins(:time_bucket)
                                  .where(time_buckets: { user_id: current_user.id })
                                  .find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Bucket item not found' }, status: :not_found
      end

      def bucket_item_params
        params.require(:bucket_item).permit(
          :title,
          :description,
          :category,
          :difficulty,
          :risk_level,
          :status,
          :value_statement,
          :cost_estimate,
          :target_year,
          :motivation_note,
          :completed_at
        )
      end
    end
  end
end
