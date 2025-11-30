require 'swagger_helper'

RSpec.describe 'api/v1/time_buckets', type: :request do
  path '/api/v1/time_buckets' do
    get('List time buckets') do
      tags 'Time Buckets'
      description 'Retrieves all time buckets for the authenticated user, ordered by position'
      produces 'application/json'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'

      response(200, 'successful') do
        schema type: :array,
          items: { '$ref' => '#/components/schemas/TimeBucket' }
        
        let(:user) { create(:user) }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end

        
        before do
          create_list(:time_bucket, 3, user: user)
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          expect(data.length).to eq(3)
        end
      end

      response(401, 'unauthorized') do
        schema '$ref' => '#/components/schemas/Error'
        
        run_test!
      end
    end

    post('Create time bucket') do
      tags 'Time Buckets'
      description 'Creates a new time bucket'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'
      
      parameter name: :time_bucket, in: :body, schema: {
        type: :object,
        properties: {
          start_age: { type: :integer, example: 30 },
          end_age: { type: :integer, example: 35 },
          granularity: { type: :string, enum: ['5y', '10y'], example: '5y' },
          description: { type: :string, example: 'Career building phase' }
        },
        required: ['start_age', 'end_age', 'granularity']
      }

      response(201, 'created') do
        schema '$ref' => '#/components/schemas/TimeBucket'
        
        let(:user) { create(:user) }
        let(:time_bucket) { { start_age: 30, end_age: 35, granularity: '5y', label: '30-35歳' } }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['start_age']).to eq(30)
          expect(data['end_age']).to eq(35)
        end
      end

      response(422, 'invalid request') do
        schema '$ref' => '#/components/schemas/ValidationError'
        
        let(:user) { create(:user) }
        let(:time_bucket) { { start_age: 35, end_age: 30 } }  # Invalid: start > end
        
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
        
        let(:time_bucket) { { start_age: 30, end_age: 35, granularity: '5y' } }
        
        run_test!
      end
    end
  end

  path '/api/v1/time_buckets/{id}' do
    parameter name: :id, in: :path, type: :integer, description: 'Time bucket ID'

    get('Show time bucket') do
      tags 'Time Buckets'
      description 'Retrieves a specific time bucket'
      produces 'application/json'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/TimeBucket'
        
        let(:user) { create(:user) }
        let(:bucket) { create(:time_bucket, user: user) }
        let(:id) { bucket.id }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['id']).to eq(bucket.id)
        end
      end

      response(404, 'not found') do
        schema '$ref' => '#/components/schemas/Error'
        
        let(:user) { create(:user) }
        let(:id) { 99999 }
        
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
        
        let(:bucket) { create(:time_bucket) }
        let(:id) { bucket.id }
        
        run_test!
      end
    end

    patch('Update time bucket') do
      tags 'Time Buckets'
      description 'Updates a specific time bucket'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'
      
      parameter name: :time_bucket, in: :body, schema: {
        type: :object,
        properties: {
          description: { type: :string, example: 'Updated description' },
          position: { type: :integer, example: 1 }
        }
      }

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/TimeBucket'
        
        let(:user) { create(:user) }
        let(:bucket) { create(:time_bucket, user: user, description: 'Old') }
        let(:id) { bucket.id }
        let(:time_bucket) { { description: 'New description' } }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['description']).to eq('New description')
        end
      end

      response(404, 'not found') do
        schema '$ref' => '#/components/schemas/Error'
        
        let(:user) { create(:user) }
        let(:id) { 99999 }
        let(:time_bucket) { { description: 'New' } }
        
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
        
        let(:bucket) { create(:time_bucket) }
        let(:id) { bucket.id }
        let(:time_bucket) { { description: 'New' } }
        
        run_test!
      end
    end

    delete('Delete time bucket') do
      tags 'Time Buckets'
      description 'Deletes a specific time bucket'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'

      response(204, 'no content') do
        let(:user) { create(:user) }
        let(:bucket) { create(:time_bucket, user: user) }
        let(:id) { bucket.id }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end
        
        run_test!
      end

      response(404, 'not found') do
        schema '$ref' => '#/components/schemas/Error'
        
        let(:user) { create(:user) }
        let(:id) { 99999 }
        
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
        
        let(:bucket) { create(:time_bucket) }
        let(:id) { bucket.id }
        
        run_test!
      end
    end
  end
end
