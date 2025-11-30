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
          category: { type: :string, enum: ['travel', 'career', 'family', 'finance', 'health', 'learning', 'other'], example: 'travel' },
          value_statement: { type: :string, example: 'Expand cultural understanding' },
          difficulty: { type: :string, enum: ['low', 'medium', 'high'], example: 'medium' },
          risk_level: { type: :string, enum: ['low', 'medium', 'high'], example: 'medium' },
          cost_estimate: { type: :integer, example: 50000 },
          target_year: { type: :integer, example: 2025 }
        },
        required: ['title', 'category']
      }

      response(201, 'created') do
        schema '$ref' => '#/components/schemas/BucketItem'
        
        let(:user) { create(:user, birthdate: '1990-01-01') }
        let(:bucket) { create(:time_bucket, user: user, start_age: 40, end_age: 49, granularity: '10y', label: '40-49歳') }
        let(:time_bucket_id) { bucket.id }
        let(:bucket_item) { { title: 'Learn Japanese', category: 'learning', value_statement: 'Personal growth and cultural understanding', target_year: 2035 } }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['title']).to eq('Learn Japanese')
          expect(data['status']).to eq('planned')
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

  path '/api/v1/bucket_items/{id}' do
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
          category: { type: :string, enum: ['travel', 'career', 'family', 'finance', 'health', 'learning', 'other'] },
          value_statement: { type: :string },
          difficulty: { type: :string, enum: ['low', 'medium', 'high'] },
          risk_level: { type: :string, enum: ['low', 'medium', 'high'] },
          cost_estimate: { type: :integer },
          target_year: { type: :integer },
          status: { type: :string, enum: ['planned', 'in_progress', 'done'] }
        }
      }

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/BucketItem'
        
        let(:user) { create(:user) }
        let(:bucket) { create(:time_bucket, user: user) }
        let(:item) { create(:bucket_item, time_bucket: bucket, title: 'Old') }
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
        let(:id) { item.id }
        
        run_test!
      end
    end
  end

  path '/api/v1/bucket_items/{id}/complete' do
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
        let(:item) { create(:bucket_item, time_bucket: bucket, status: 'in_progress') }
        let(:id) { item.id }
        
        let(:user_session) { create(:session, user: user) }
        
        let(:Cookie) do
        
          jar = ActionDispatch::Cookies::CookieJar.build(ActionDispatch::TestRequest.create, {})
        
          jar.signed[:session_token] = user_session.token
        
          jar.instance_variable_get(:@set_cookies).transform_values { |v| v[:value] }.map { |k, v| "#{k}=#{v}" }.join('; ')
        
        end
        
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['status']).to eq('done')
          expect(data['completed_at']).to be_present
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
        let(:item) { create(:bucket_item, time_bucket: bucket) }
        let(:id) { item.id }
        
        run_test!
      end
    end
  end
end
