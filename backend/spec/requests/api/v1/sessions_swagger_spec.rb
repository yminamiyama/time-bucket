require 'swagger_helper'

RSpec.describe 'api/v1/sessions', type: :request do
  path '/auth/google_oauth2/callback' do
    post('Google OAuth callback (production)') do
      tags 'Authentication'
      description 'Google OAuth 2.0 callback endpoint for user authentication (production environment)'
      produces 'application/json'
      consumes 'application/x-www-form-urlencoded'
      
      parameter name: :code, in: :query, type: :string, description: 'OAuth authorization code', required: true
      parameter name: :state, in: :query, type: :string, description: 'OAuth state parameter', required: true

      response(200, 'authentication successful') do
        schema type: :object,
          properties: {
            message: { type: :string, example: 'Successfully authenticated' },
            user: { '$ref' => '#/components/schemas/User' }
          },
          required: ['message', 'user']
        
        # This endpoint requires actual OAuth flow, so we'll document it without running tests
        let(:code) { 'oauth_authorization_code' }
        let(:state) { 'csrf_state_token' }
        
        # Note: Real authentication flow cannot be easily tested in specs
        # This documents the expected successful response
        run_test! do |response|
          # In production, this would validate OAuth with Google and create a session
        end
      end

      response(401, 'authentication failed') do
        schema '$ref' => '#/components/schemas/Error'
        
        # Documents the error case when OAuth fails
        run_test!
      end
    end

    get('Google OAuth callback (development)') do
      tags 'Authentication'
      description 'Google OAuth 2.0 callback endpoint for user authentication (development environment only)'
      produces 'application/json'
      
      parameter name: :code, in: :query, type: :string, description: 'OAuth authorization code', required: true
      parameter name: :state, in: :query, type: :string, description: 'OAuth state parameter', required: true

      response(200, 'authentication successful') do
        schema type: :object,
          properties: {
            message: { type: :string, example: 'Successfully authenticated' },
            user: { '$ref' => '#/components/schemas/User' }
          },
          required: ['message', 'user']
        
        let(:code) { 'oauth_authorization_code' }
        let(:state) { 'csrf_state_token' }
        
        run_test!
      end
    end
  end

  path '/auth/google_oauth2' do
    get('Initiate Google OAuth (development)') do
      tags 'Authentication'
      description 'Redirects to Google OAuth consent screen (development environment only)'
      produces 'text/html'

      response(302, 'redirect to Google') do
        run_test! do |response|
          expect(response).to have_http_status(:found)
          expect(response.location).to include('accounts.google.com')
        end
      end
    end

    post('Initiate Google OAuth (production)') do
      tags 'Authentication'
      description 'Redirects to Google OAuth consent screen (production environment)'
      produces 'text/html'

      response(302, 'redirect to Google') do
        run_test! do |response|
          expect(response).to have_http_status(:found)
          expect(response.location).to include('accounts.google.com')
        end
      end
    end
  end

  path '/api/v1/sessions' do
    delete('Logout') do
      tags 'Authentication'
      description 'Logs out the current user by destroying their session'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'

      response(200, 'logged out successfully') do
        schema type: :object,
          properties: {
            message: { type: :string, example: 'Logged out successfully' }
          },
          required: ['message']
        
        let(:user) { create(:user) }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to eq('Logged out successfully')
        end
      end

      response(401, 'not authenticated') do
        schema '$ref' => '#/components/schemas/Error'
        
        run_test!
      end
    end
  end

  path '/auth/failure' do
    get('OAuth failure callback') do
      tags 'Authentication'
      description 'Handles OAuth authentication failures'
      produces 'application/json'
      
      parameter name: :message, in: :query, type: :string, description: 'Error message from OAuth provider'
      parameter name: :strategy, in: :query, type: :string, description: 'OAuth strategy that failed'

      response(401, 'authentication failed') do
        schema type: :object,
          properties: {
            error: { type: :string, example: 'Authentication failed' },
            message: { type: :string, example: 'invalid_credentials' },
            strategy: { type: :string, example: 'google_oauth2' }
          },
          required: ['error']
        
        let(:message) { 'invalid_credentials' }
        let(:strategy) { 'google_oauth2' }
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Authentication failed')
        end
      end
    end
  end
end
