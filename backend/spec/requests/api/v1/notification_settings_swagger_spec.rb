require 'swagger_helper'

RSpec.describe 'api/v1/notification_settings', type: :request do
  path '/api/v1/notification-settings' do
    get('Get notification settings') do
      tags 'Notification Settings'
      description 'Retrieves the authenticated user notification preferences'
      produces 'application/json'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/NotificationPreference'
        
        let(:user) { create(:user) }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('email_enabled')
          expect(data).to have_key('slack_webhook_url')
          expect(data).to have_key('digest_time')
          expect(data).to have_key('events')
        end
      end

      response(401, 'unauthorized') do
        schema '$ref' => '#/components/schemas/Error'
        
        run_test!
      end
    end

    patch('Update notification settings') do
      tags 'Notification Settings'
      description 'Updates the authenticated user notification preferences'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'
      
      parameter name: :notification_settings, in: :body, schema: {
        type: :object,
        properties: {
          email_enabled: { type: :boolean, example: true },
          slack_webhook_url: { type: :string, format: :uri, example: 'https://hooks.slack.com/services/XXX' },
          digest_time: { type: :string, pattern: '^([01]\d|2[0-3]):[0-5]\d$', example: '09:00' },
          events: {
            type: :object,
            properties: {
              bucket_item_completed: { type: :boolean, example: true },
              bucket_item_due_soon: { type: :boolean, example: true },
              weekly_summary: { type: :boolean, example: false }
            }
          }
        }
      }

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/NotificationPreference'
        
        let(:user) { create(:user) }
        let(:notification_settings) { { email_enabled: false } }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['email_enabled']).to eq(false)
        end
      end

      response(422, 'invalid request') do
        schema '$ref' => '#/components/schemas/ValidationError'
        
        let(:user) { create(:user) }
        let(:notification_settings) { { digest_time: 'invalid' } }  # Invalid time format
        
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
        
        let(:notification_settings) { { email_enabled: true } }
        
        run_test!
      end
    end
  end
end
