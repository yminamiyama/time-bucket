require 'swagger_helper'

RSpec.describe 'api/v1/time_buckets/templates', type: :request do
  path '/api/v1/time_buckets/templates' do
    post('Generate time bucket templates') do
      tags 'Time Buckets'
      description 'Generates time bucket templates based on user age (20-100 years old, 5-year intervals)'
      produces 'application/json'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'
      
      parameter name: :granularity, in: :query, type: :string, required: true, 
        enum: ['5y', '10y'], 
        description: 'Time interval for templates'

      response(201, 'templates created') do
        schema type: :object,
          properties: {
            message: { type: :string },
            count: { type: :integer },
            buckets: {
              type: :array,
              items: { '$ref' => '#/components/schemas/TimeBucket' }
            }
          },
          required: ['message', 'count', 'buckets']
        
        let(:user) { create(:user, birthdate: '1990-01-01') }
        let(:granularity) { '10y' }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['buckets']).to be_an(Array)
          expect(data['count']).to eq(8)  # (100-20)/10 = 8 buckets for 10y granularity
          expect(data['buckets'].first['start_age']).to eq(20)
          expect(data['buckets'].last['end_age']).to eq(100)
        end
      end

      response(422, 'templates already exist') do
        schema '$ref' => '#/components/schemas/Error'
        
        let(:user) { create(:user) }
        let(:granularity) { '10y' }
        
        before do
          create(:time_bucket, user: user, start_age: 20, end_age: 29, granularity: '10y', label: '20-29歳')
        end
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['errors']).to be_present
        end
      end

      response(401, 'unauthorized') do
        schema '$ref' => '#/components/schemas/Error'
        
        let(:granularity) { '10y' }
        
        run_test!
      end
    end
  end
end
