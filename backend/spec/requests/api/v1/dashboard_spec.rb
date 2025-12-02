require 'rails_helper'

RSpec.describe 'Api::V1::Dashboard', type: :request do
  include AuthenticationHelper

  let(:user) { create(:user, birthdate: Date.new(1990, 1, 1)) }
  let(:session) { create(:session, user: user) }
  let!(:bucket1) { create(:time_bucket, user: user, label: '30s', start_age: 30, end_age: 39, position: 0) }
  let!(:bucket2) { create(:time_bucket, user: user, label: '40s', start_age: 40, end_age: 49, position: 1) }

  describe 'GET /v1/dashboard/summary' do
    context 'when authenticated' do
      it 'returns dashboard summary with empty data' do
        get '/v1/dashboard/summary', headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['total_items']).to eq(0)
        expect(json['total_buckets']).to eq(2)
        expect(json['bucket_density']).to be_an(Array)
        expect(json['bucket_density'].length).to eq(2)
        
        # All categories should be included even when there are no items
        expect(json['category_distribution']).to be_an(Array)
        expect(json['category_distribution'].length).to eq(BucketItem::CATEGORIES.length)
        json['category_distribution'].each do |category|
          expect(category['count']).to eq(0)
          expect(category['percentage']).to eq(0.0)
        end
        
        expect(json['completion_stats']).to be_a(Hash)
        expect(json['completion_stats']['total']).to eq(0)
        expect(json['completion_stats']['completion_rate']).to eq(0)
      end

      it 'returns correct bucket density' do
        create(:bucket_item, time_bucket: bucket1, target_year: 2020, cost_estimate: 1000)
        create(:bucket_item, time_bucket: bucket1, target_year: 2021, cost_estimate: 2000)
        create(:bucket_item, time_bucket: bucket2, target_year: 2030, cost_estimate: 500)

        get '/v1/dashboard/summary', headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        density = json['bucket_density']
        expect(density.length).to eq(2)

        bucket1_data = density.find { |d| d['bucket_id'] == bucket1.id }
        expect(bucket1_data['label']).to eq('30s')
        expect(bucket1_data['item_count']).to eq(2)
        expect(bucket1_data['total_cost']).to eq(3000)

        bucket2_data = density.find { |d| d['bucket_id'] == bucket2.id }
        expect(bucket2_data['item_count']).to eq(1)
        expect(bucket2_data['total_cost']).to eq(500)
      end

      it 'returns correct category distribution' do
        create(:bucket_item, :travel, time_bucket: bucket1, target_year: 2020)
        create(:bucket_item, :travel, time_bucket: bucket1, target_year: 2021)
        create(:bucket_item, :career, time_bucket: bucket1, target_year: 2022)
        create(:bucket_item, :family, time_bucket: bucket2, target_year: 2030)

        get '/v1/dashboard/summary', headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        distribution = json['category_distribution']
        expect(distribution).to be_an(Array)
        expect(distribution.length).to eq(BucketItem::CATEGORIES.length)

        travel = distribution.find { |d| d['category'] == 'travel' }
        expect(travel['count']).to eq(2)
        expect(travel['percentage']).to eq(50.0)

        career = distribution.find { |d| d['category'] == 'career' }
        expect(career['count']).to eq(1)
        expect(career['percentage']).to eq(25.0)

        family = distribution.find { |d| d['category'] == 'family' }
        expect(family['count']).to eq(1)
        expect(family['percentage']).to eq(25.0)

        # Categories with no items should have 0 count
        finance = distribution.find { |d| d['category'] == 'finance' }
        expect(finance['count']).to eq(0)
        expect(finance['percentage']).to eq(0.0)
      end

      it 'returns correct completion stats' do
        create(:bucket_item, time_bucket: bucket1, status: 'planned', target_year: 2020)
        create(:bucket_item, time_bucket: bucket1, status: 'planned', target_year: 2021)
        create(:bucket_item, time_bucket: bucket1, status: 'in_progress', target_year: 2022)
        create(:bucket_item, :done, time_bucket: bucket2, target_year: 2030)
        create(:bucket_item, :done, time_bucket: bucket2, target_year: 2031)

        get '/v1/dashboard/summary', headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        stats = json['completion_stats']
        expect(stats['total']).to eq(5)
        expect(stats['planned']).to eq(2)
        expect(stats['in_progress']).to eq(1)
        expect(stats['completed']).to eq(2)
        expect(stats['completion_rate']).to eq(40.0)
      end

      it 'handles buckets with no items' do
        get '/v1/dashboard/summary', headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['completion_stats']['total']).to eq(0)
        expect(json['completion_stats']['completion_rate']).to eq(0)
      end

      it 'only shows data for authenticated user' do
        other_user = create(:user, birthdate: Date.new(1985, 1, 1))
        other_bucket = create(:time_bucket, user: other_user, start_age: 40, end_age: 49)
        create(:bucket_item, time_bucket: other_bucket, target_year: 2025)

        create(:bucket_item, time_bucket: bucket1, target_year: 2020)

        get '/v1/dashboard/summary', headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['total_items']).to eq(1)
        expect(json['total_buckets']).to eq(2)
      end
    end

    context 'when not authenticated' do
      it 'returns 401 unauthorized' do
        get '/v1/dashboard/summary'

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
