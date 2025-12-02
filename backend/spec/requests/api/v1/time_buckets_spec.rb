require 'rails_helper'

RSpec.describe "Api::V1::TimeBuckets", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:session) { create(:session, user: user) }
  let(:other_session) { create(:session, user: other_user) }
  
  let(:valid_attributes) do
    {
      label: "20-30歳",
      start_age: 20,
      end_age: 30,
      granularity: "5y",
      position: 0
    }
  end
  
  let(:invalid_attributes) do
    {
      label: "",
      start_age: 30,
      end_age: 20,
      granularity: "invalid",
      position: -1
    }
  end

  describe "GET /v1/time_buckets" do
    context "when authenticated" do
      it "returns user's time buckets only" do
        create_list(:time_bucket, 3, user: user)
        create_list(:time_bucket, 2, user: other_user)
        
        get "/v1/time_buckets", headers: auth_headers(session)
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json.length).to eq(3)
      end
      
      it "returns time buckets in order" do
        bucket1 = create(:time_bucket, user: user, position: 2)
        bucket2 = create(:time_bucket, user: user, position: 0)
        bucket3 = create(:time_bucket, user: user, position: 1)
        
        get "/v1/time_buckets", headers: auth_headers(session)
        
        json = JSON.parse(response.body)
        expect(json.map { |b| b['id'] }).to eq([bucket2.id, bucket3.id, bucket1.id])
      end
    end
    
    context 'when not authenticated' do
      it 'returns 401' do
        get '/v1/time_buckets'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /v1/time_buckets/:id" do
    let(:time_bucket) { create(:time_bucket, user: user) }
    
    context "when authenticated" do
      it "returns the time bucket" do
        get "/v1/time_buckets/#{time_bucket.id}", headers: auth_headers(session)
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['id']).to eq(time_bucket.id)
        expect(json['label']).to eq(time_bucket.label)
      end
    end
    
    context "when accessing other user's bucket" do
      let(:other_bucket) { create(:time_bucket, user: other_user) }
      
      it "returns 404" do
        get "/v1/time_buckets/#{other_bucket.id}", headers: auth_headers(session)
        expect(response).to have_http_status(:not_found)
      end
    end
    
    context "when not authenticated" do
      it "returns 401" do
        get "/v1/time_buckets/#{time_bucket.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /v1/time_buckets" do
    context "with valid parameters" do
      it "creates a new time bucket" do
        expect {
          post "/v1/time_buckets",
               params: { time_bucket: valid_attributes },
               headers: auth_headers(session)
        }.to change(TimeBucket, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['label']).to eq(valid_attributes[:label])
      end
    end
    
    context "with invalid parameters" do
      it "returns unprocessable entity" do
        post "/v1/time_buckets",
             params: { time_bucket: invalid_attributes },
             headers: auth_headers(session)
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end
    
    context "when not authenticated" do
      it "returns 401" do
        post "/v1/time_buckets", params: { time_bucket: valid_attributes }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PATCH /v1/time_buckets/:id" do
    let(:time_bucket) { create(:time_bucket, user: user) }
    let(:new_attributes) { { label: "Updated Label" } }
    
    context "with valid parameters" do
      it "updates the time bucket" do
        patch "/v1/time_buckets/#{time_bucket.id}",
              params: { time_bucket: new_attributes },
              headers: auth_headers(session)
        
        expect(response).to have_http_status(:success)
        time_bucket.reload
        expect(time_bucket.label).to eq("Updated Label")
      end
    end
    
    context "with invalid parameters" do
      it "returns unprocessable entity" do
        patch "/v1/time_buckets/#{time_bucket.id}",
              params: { time_bucket: { start_age: 100, end_age: 20 } },
              headers: auth_headers(session)
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
    
    context "when accessing other user's bucket" do
      let(:other_bucket) { create(:time_bucket, user: other_user) }
      
      it "returns 404" do
        patch "/v1/time_buckets/#{other_bucket.id}",
              params: { time_bucket: new_attributes },
              headers: auth_headers(session)
        
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /v1/time_buckets/:id" do
    let!(:time_bucket) { create(:time_bucket, user: user) }
    
    context "when authenticated" do
      it "destroys the time bucket" do
        expect {
          delete "/v1/time_buckets/#{time_bucket.id}", headers: auth_headers(session)
        }.to change(TimeBucket, :count).by(-1)
        
        expect(response).to have_http_status(:no_content)
      end
    end
    
    context "when accessing other user's bucket" do
      let!(:other_bucket) { create(:time_bucket, user: other_user) }
      
      it "returns 404" do
        expect {
          delete "/v1/time_buckets/#{other_bucket.id}", headers: auth_headers(session)
        }.not_to change(TimeBucket, :count)
        
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
