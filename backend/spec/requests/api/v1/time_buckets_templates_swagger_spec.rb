require 'swagger_helper'

RSpec.describe 'api/v1/time_buckets/templates', type: :request do
  path '/api/v1/time_buckets/templates' do
    post('Generate time bucket templates') do
      tags 'Time Buckets'
      description 'Generates time bucket templates based on user age (20-100 years old, 5-year intervals)'
      produces 'application/json'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'

      response(201, 'templates created') do
        schema type: :array,
          items: { '$ref' => '#/components/schemas/TimeBucket' }
        
        let(:user) { create(:user, birthdate: '1990-01-01') }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          expect(data.length).to eq(16)  # (100-20)/5 = 16 buckets
          expect(data.first['start_age']).to eq(20)
          expect(data.last['end_age']).to eq(100)
        end
      end

      response(422, 'templates already exist') do
        schema '$ref' => '#/components/schemas/Error'
        
        let(:user) { create(:user) }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end

        
        before do
          create(:time_bucket, user: user)
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to be_present
        end
      end

      response(401, 'unauthorized') do
        schema '$ref' => '#/components/schemas/Error'
        
        run_test!
      end
    end
  end
end
