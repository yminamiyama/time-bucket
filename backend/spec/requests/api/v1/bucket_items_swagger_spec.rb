require 'swagger_helper'

RSpec.describe 'api/v1/time_buckets/{time_bucket_id}/bucket_items', type: :request do
  path '/api/v1/time_buckets/{time_bucket_id}/bucket_items' do
    parameter name: :time_bucket_id, in: :path, type: :integer, description: 'Time bucket ID'

    get('List bucket items') do
      tags 'Bucket Items'
      description 'Retrieves all bucket items for a specific time bucket'
      produces 'application/json'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'

      response(200, 'successful') do
        schema type: :array,
          items: { '$ref' => '#/components/schemas/BucketItem' }
        
        let(:user) { create(:user) }
        let(:bucket) { create(:time_bucket, user: user) }
        let(:time_bucket_id) { bucket.id }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end

        
        before do
          create_list(:bucket_item, 3, time_bucket: bucket)
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          expect(data.length).to eq(3)
        end
      end

      response(404, 'time bucket not found') do
        schema '$ref' => '#/components/schemas/Error'
        
        let(:user) { create(:user) }
        let(:time_bucket_id) { 99999 }
        
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
        let(:time_bucket_id) { bucket.id }
        
        run_test!
      end
    end

    post('Create bucket item') do
      tags 'Bucket Items'
      description 'Creates a new bucket item'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'
      
      parameter name: :bucket_item, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string, example: 'Learn a new language' },
          category: { type: :string, enum: ['learning', 'career', 'relationships', 'health', 'finance', 'personal_growth', 'hobbies', 'other'], example: 'learning' },
          value_statement: { type: :string, example: 'Expand cultural understanding' },
          difficulty: { type: :integer, minimum: 1, maximum: 5, example: 3 },
          risk_level: { type: :integer, minimum: 1, maximum: 5, example: 2 },
          estimated_cost: { type: :integer, example: 50000 },
          target_year: { type: :integer, example: 2025 }
        },
        required: ['title', 'category']
      }

      response(201, 'created') do
        schema '$ref' => '#/components/schemas/BucketItem'
        
        let(:user) { create(:user) }
        let(:bucket) { create(:time_bucket, user: user) }
        let(:time_bucket_id) { bucket.id }
        let(:bucket_item) { { title: 'Learn Japanese', category: 'learning' } }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['title']).to eq('Learn Japanese')
          expect(data['status']).to eq('active')
        end
      end

      response(422, 'invalid request') do
        schema '$ref' => '#/components/schemas/ValidationError'
        
        let(:user) { create(:user) }
        let(:bucket) { create(:time_bucket, user: user) }
        let(:time_bucket_id) { bucket.id }
        let(:bucket_item) { { title: '' } }  # Missing required fields
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end
        
        run_test!
      end

      response(404, 'time bucket not found') do
        schema '$ref' => '#/components/schemas/Error'
        
        let(:user) { create(:user) }
        let(:time_bucket_id) { 99999 }
        let(:bucket_item) { { title: 'Test', category: 'learning' } }
        
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
        let(:time_bucket_id) { bucket.id }
        let(:bucket_item) { { title: 'Test', category: 'learning' } }
        
        run_test!
      end
    end
  end

  path '/api/v1/time_buckets/{time_bucket_id}/bucket_items/{id}' do
    parameter name: :time_bucket_id, in: :path, type: :integer, description: 'Time bucket ID'
    parameter name: :id, in: :path, type: :integer, description: 'Bucket item ID'

    get('Show bucket item') do
      tags 'Bucket Items'
      description 'Retrieves a specific bucket item'
      produces 'application/json'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/BucketItem'
        
        let(:user) { create(:user) }
        let(:bucket) { create(:time_bucket, user: user) }
        let(:item) { create(:bucket_item, time_bucket: bucket) }
        let(:time_bucket_id) { bucket.id }
        let(:id) { item.id }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['id']).to eq(item.id)
        end
      end

      response(404, 'not found') do
        schema '$ref' => '#/components/schemas/Error'
        
        let(:user) { create(:user) }
        let(:bucket) { create(:time_bucket, user: user) }
        let(:time_bucket_id) { bucket.id }
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
        let(:item) { create(:bucket_item, time_bucket: bucket) }
        let(:time_bucket_id) { bucket.id }
        let(:id) { item.id }
        
        run_test!
      end
    end

    patch('Update bucket item') do
      tags 'Bucket Items'
      description 'Updates a specific bucket item'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'
      
      parameter name: :bucket_item, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string },
          category: { type: :string, enum: ['learning', 'career', 'relationships', 'health', 'finance', 'personal_growth', 'hobbies', 'other'] },
          value_statement: { type: :string },
          difficulty: { type: :integer, minimum: 1, maximum: 5 },
          risk_level: { type: :integer, minimum: 1, maximum: 5 },
          estimated_cost: { type: :integer },
          target_year: { type: :integer },
          status: { type: :string, enum: ['active', 'completed', 'archived'] }
        }
      }

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/BucketItem'
        
        let(:user) { create(:user) }
        let(:bucket) { create(:time_bucket, user: user) }
        let(:item) { create(:bucket_item, time_bucket: bucket, title: 'Old') }
        let(:time_bucket_id) { bucket.id }
        let(:id) { item.id }
        let(:bucket_item) { { title: 'Updated title' } }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['title']).to eq('Updated title')
        end
      end

      response(404, 'not found') do
        schema '$ref' => '#/components/schemas/Error'
        
        let(:user) { create(:user) }
        let(:bucket) { create(:time_bucket, user: user) }
        let(:time_bucket_id) { bucket.id }
        let(:id) { 99999 }
        let(:bucket_item) { { title: 'New' } }
        
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
        let(:item) { create(:bucket_item, time_bucket: bucket) }
        let(:time_bucket_id) { bucket.id }
        let(:id) { item.id }
        let(:bucket_item) { { title: 'New' } }
        
        run_test!
      end
    end

    delete('Delete bucket item') do
      tags 'Bucket Items'
      description 'Deletes a specific bucket item'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'

      response(204, 'no content') do
        let(:user) { create(:user) }
        let(:bucket) { create(:time_bucket, user: user) }
        let(:item) { create(:bucket_item, time_bucket: bucket) }
        let(:time_bucket_id) { bucket.id }
        let(:id) { item.id }
        
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
        let(:bucket) { create(:time_bucket, user: user) }
        let(:time_bucket_id) { bucket.id }
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
        let(:item) { create(:bucket_item, time_bucket: bucket) }
        let(:time_bucket_id) { bucket.id }
        let(:id) { item.id }
        
        run_test!
      end
    end
  end

  path '/api/v1/time_buckets/{time_bucket_id}/bucket_items/{id}/complete' do
    parameter name: :time_bucket_id, in: :path, type: :integer, description: 'Time bucket ID'
    parameter name: :id, in: :path, type: :integer, description: 'Bucket item ID'

    patch('Mark bucket item as completed') do
      tags 'Bucket Items'
      description 'Marks a bucket item as completed and sets completed_at timestamp'
      produces 'application/json'
      parameter name: :Cookie, in: :header, type: :string, required: false, description: 'Session cookie'

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/BucketItem'
        
        let(:user) { create(:user) }
        let(:bucket) { create(:time_bucket, user: user) }
        let(:item) { create(:bucket_item, time_bucket: bucket, status: 'active') }
        let(:time_bucket_id) { bucket.id }
        let(:id) { item.id }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq('completed')
          expect(data['completed_at']).to be_present
        end
      end

      response(404, 'not found') do
        schema '$ref' => '#/components/schemas/Error'
        
        let(:user) { create(:user) }
        let(:bucket) { create(:time_bucket, user: user) }
        let(:time_bucket_id) { bucket.id }
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
        let(:item) { create(:bucket_item, time_bucket: bucket) }
        let(:time_bucket_id) { bucket.id }
        let(:id) { item.id }
        
        run_test!
      end
    end
  end
end
