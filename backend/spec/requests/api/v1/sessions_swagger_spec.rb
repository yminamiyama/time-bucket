require 'swagger_helper'

RSpec.describe 'api/v1/sessions', type: :request do
  path '/auth/google_oauth2/callback' do
    post('Google OAuth callback (production)') do
      tags 'Authentication'
      description 'Google OAuth 2.0 callback endpoint - redirects to frontend with authentication result'
      produces 'text/html'
      consumes 'application/x-www-form-urlencoded'
      
      parameter name: :code, in: :query, type: :string, description: 'OAuth authorization code', required: true
      parameter name: :state, in: :query, type: :string, description: 'OAuth state parameter', required: true

      response(302, 'redirect after OAuth processing') do
        let(:code) { 'oauth_authorization_code' }
        let(:state) { 'csrf_state_token' }
        
        run_test! do |response|
          expect(response).to have_http_status(:found)
          # Note: Real OAuth flow requires proper state/CSRF tokens
          # This test validates the redirect behavior
        end
      end
    end

    get('Google OAuth callback (development)') do
      tags 'Authentication'
      description 'Google OAuth 2.0 callback endpoint for development - redirects to frontend'
      produces 'text/html'
      
      parameter name: :code, in: :query, type: :string, description: 'OAuth authorization code', required: true
      parameter name: :state, in: :query, type: :string, description: 'OAuth state parameter', required: true

      response(302, 'redirect after OAuth processing') do
        let(:code) { 'oauth_authorization_code' }
        let(:state) { 'csrf_state_token' }
        
        run_test! do |response|
          expect(response).to have_http_status(:found)
          # Note: Real OAuth flow requires proper state/CSRF tokens
        end
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

  path '/logout' do
    delete('Logout') do
      tags 'Authentication'
      description 'Logs out the current user and redirects to frontend'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'

      response(302, 'redirect to frontend after logout') do
        let(:user) { create(:user) }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end
        
        run_test! do |response|
          expect(response).to have_http_status(:found)
          expect(response.location).to include('localhost:3000')
        end
      end

      response(302, 'redirect even without authentication') do
        run_test! do |response|
          expect(response).to have_http_status(:found)
          expect(response.location).to include('localhost:3000')
        end
      end
    end
  end

  path '/auth/failure' do
    get('OAuth failure callback') do
      tags 'Authentication'
      description 'Handles OAuth authentication failures - redirects to frontend with error'
      produces 'text/html'
      
      parameter name: :message, in: :query, type: :string, description: 'Error message from OAuth provider'
      parameter name: :strategy, in: :query, type: :string, description: 'OAuth strategy that failed'

      response(302, 'redirect to frontend with error') do
        let(:message) { 'invalid_credentials' }
        let(:strategy) { 'google_oauth2' }
        
        run_test! do |response|
          expect(response).to have_http_status(:found)
          expect(response.location).to include('localhost:3000')
        end
      end
    end
  end
end
