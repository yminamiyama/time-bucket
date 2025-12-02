require 'swagger_helper'

RSpec.describe 'api/v1/profile', type: :request do
  path '/v1/profile' do
    get('Get user profile') do
      tags 'Profile'
      description 'Retrieves the authenticated user profile information'
      produces 'application/json'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/User'
        
        let(:user) { create(:user) }
        let(:user_session) { create(:session, user: user) }
        let(:Cookie) do
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
          jar.signed[:session_token] = user_session.token
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['id']).to eq(user.id)
          expect(data['email']).to eq(user.email)
        end
      end

      response(401, 'unauthorized') do
        schema '$ref' => '#/components/schemas/Error'
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Unauthorized')
        end
      end
    end

    patch('Update user profile') do
      tags 'Profile'
      description 'Updates the authenticated user profile information'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'
      
      parameter name: :profile, in: :body, schema: {
        type: :object,
        properties: {
          birthdate: { type: :string, format: :date, example: '1990-01-01' },
          timezone: { type: :string, example: 'Asia/Tokyo' }
        }
      }

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/User'
        
        let(:user) { create(:user, birthdate: '2000-01-01') }
        let(:profile) { { birthdate: '1995-06-15' } }
        
        let(:user_session) { create(:session, user: user) }
        let(:Cookie) do
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
          jar.signed[:session_token] = user_session.token
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['birthdate']).to eq('1995-06-15')
        end
      end

      response(422, 'invalid request') do
        schema '$ref' => '#/components/schemas/ValidationError'
        
        let(:user) { create(:user) }
        let(:profile) { { birthdate: '2030-01-01' } }  # Future date
        
        let(:user_session) { create(:session, user: user) }
        let(:Cookie) do
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
          jar.signed[:session_token] = user_session.token
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        end
        
        run_test!
      end

      response(401, 'unauthorized') do
        schema '$ref' => '#/components/schemas/Error'
        
        let(:profile) { { birthdate: '1995-06-15' } }
        
        run_test!
      end
    end
  end
end
