require 'swagger_helper'

RSpec.describe 'api/v1/dashboard', type: :request do
  path '/v1/dashboard/summary' do
    get('Get dashboard summary') do
      tags 'Dashboard'
      description 'Retrieves dashboard summary statistics including bucket counts and item progress'
      produces 'application/json'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'

      response(200, 'successful') do
        schema type: :object,
          properties: {
            bucket_density: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  bucket_id: { type: :string, format: :uuid },
                  label: { type: :string },
                  start_age: { type: :integer },
                  end_age: { type: :integer },
                  item_count: { type: :integer },
                  total_cost: { type: :number }
                }
              }
            },
            category_distribution: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  category: { type: :string },
                  count: { type: :integer },
                  percentage: { type: :number }
                }
              }
            },
            completion_stats: {
              type: :object,
              properties: {
                total: { type: :integer },
                completed: { type: :integer },
                in_progress: { type: :integer },
                planned: { type: :integer },
                completion_rate: { type: :number }
              }
            },
            total_buckets: { type: :integer },
            total_items: { type: :integer }
          },
          required: ['bucket_density', 'category_distribution', 'completion_stats', 'total_buckets', 'total_items']
        
        let(:user) { create(:user) }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end

        
        before do
          bucket = create(:time_bucket, user: user)
          create(:bucket_item, time_bucket: bucket, status: 'in_progress')
          create(:bucket_item, time_bucket: bucket, status: 'done', completed_at: Time.current)
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['total_buckets']).to eq(1)
          expect(data['total_items']).to eq(2)
          expect(data['completion_stats']['completed']).to eq(1)
          expect(data['completion_stats']['in_progress']).to eq(1)
        end
      end

      response(401, 'unauthorized') do
        schema '$ref' => '#/components/schemas/Error'
        
        run_test!
      end
    end
  end

  path '/v1/dashboard/actions-now' do
    get('Get actions for current time bucket') do
      tags 'Dashboard'
      description 'Retrieves bucket items that should be actioned now based on user current age'
      produces 'application/json'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'

      response(200, 'successful') do
        schema type: :object,
          properties: {
            current_age: { type: :integer },
            current_year: { type: :integer },
            threshold_years: { type: :integer },
            items: {
              type: :array,
              items: { type: :object }
            }
          },
          required: ['current_age', 'current_year', 'threshold_years', 'items']
        
        let(:user) { create(:user, birthdate: 30.years.ago) }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end

        
        before do
          bucket = create(:time_bucket, user: user, start_age: 25, end_age: 35)
          create_list(:bucket_item, 3, time_bucket: bucket, status: 'in_progress')
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['items']).to be_an(Array)
          expect(data['items'].length).to eq(3)
        end
      end

      response(401, 'unauthorized') do
        schema '$ref' => '#/components/schemas/Error'
        
        run_test!
      end
    end
  end

  path '/v1/dashboard/review-completed' do
    get('Get recently completed items for review') do
      tags 'Dashboard'
      description 'Retrieves recently completed bucket items for review'
      produces 'application/json'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'

      response(200, 'successful') do
        schema type: :object,
          properties: {
            total_completed: { type: :integer },
            total_cost: { type: :number },
            category_achievements: { type: :array },
            bucket_completions: { type: :array },
            items: { type: :array }
          },
          required: ['total_completed', 'total_cost', 'category_achievements', 'bucket_completions', 'items']
        
        let(:user) { create(:user) }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end

        
        before do
          bucket = create(:time_bucket, user: user)
          create_list(:bucket_item, 5, time_bucket: bucket, status: 'done', completed_at: 1.day.ago)
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['items']).to be_an(Array)
          expect(data['items'].length).to eq(5)
          expect(data['total_completed']).to eq(5)
        end
      end

      response(401, 'unauthorized') do
        schema '$ref' => '#/components/schemas/Error'
        
        run_test!
      end
    end
  end
end
