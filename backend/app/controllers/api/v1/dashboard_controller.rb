module Api
  module V1
    class DashboardController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/dashboard/summary
      def summary
        # Fetch all bucket items for stats calculation in a single query
        bucket_items = BucketItem.joins(:time_bucket).where(time_buckets: { user_id: current_user.id })
        
        render json: {
          bucket_density: calculate_bucket_density,
          category_distribution: calculate_category_distribution(bucket_items),
          completion_stats: calculate_completion_stats(bucket_items),
          total_items: bucket_items.count,
          total_buckets: current_user.time_buckets.count
        }
      end

      # GET /api/v1/dashboard/actions-now
      def actions_now
        unless current_user.birthdate
          render json: { error: "Birthdate is required to calculate actions now" }, status: :bad_request
          return
        end

        current_age = current_user.current_age
        current_year = Date.today.year
        threshold_years = 5

        items = BucketItem.joins(:time_bucket)
                          .where(time_buckets: { user_id: current_user.id })
                          .where.not(status: 'done')
                          .select("bucket_items.*, time_buckets.label as bucket_label")

        actions = items.filter_map do |item|
          next unless item.target_year

          year_diff = item.target_year - current_year
          reason = if year_diff < 0
            "overdue"
          elsif year_diff <= threshold_years
            "approaching"
          end

          next unless reason

          {
            id: item.id,
            title: item.title,
            category: item.category,
            difficulty: item.difficulty,
            risk_level: item.risk_level,
            target_year: item.target_year,
            bucket_label: item.bucket_label,
            status: item.status,
            reason: reason,
            years_until: year_diff
          }
        end

        render json: {
          current_age: current_age,
          current_year: current_year,
          threshold_years: threshold_years,
          items: actions.sort_by { |a| a[:years_until] }
        }
      end

      private

      def calculate_bucket_density
        current_user.time_buckets.includes(:bucket_items).map do |bucket|
          {
            bucket_id: bucket.id,
            label: bucket.label,
            start_age: bucket.start_age,
            end_age: bucket.end_age,
            item_count: bucket.bucket_items.count,
            total_cost: bucket.bucket_items.sum(:cost_estimate)
          }
        end
      end

      def calculate_category_distribution(items)
        total = items.count
        distribution = items.group_by(&:category).transform_values(&:count)
        
        BucketItem::CATEGORIES.map do |category|
          count = distribution[category] || 0
          {
            category: category,
            count: count,
            percentage: total.zero? ? 0 : ((count.to_f / total) * 100).round(2)
          }
        end
      end

      def calculate_completion_stats(items)
        total = items.count
        status_counts = items.group_by(&:status).transform_values(&:count)
        
        completed = status_counts['done'] || 0
        in_progress = status_counts['in_progress'] || 0
        planned = status_counts['planned'] || 0

        {
          total: total,
          completed: completed,
          in_progress: in_progress,
          planned: planned,
          completion_rate: total.zero? ? 0 : ((completed.to_f / total) * 100).round(2)
        }
      end
    end
  end
end
