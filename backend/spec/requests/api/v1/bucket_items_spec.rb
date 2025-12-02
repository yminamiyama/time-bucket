require 'rails_helper'

RSpec.describe "Api::V1::BucketItems", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:session) { create(:session, user: user) }
  let(:time_bucket) { create(:time_bucket, user: user) }
  let(:other_time_bucket) { create(:time_bucket, user: other_user) }
  
  let(:valid_attributes) do
    {
      title: "世界一周旅行",
      description: "バックパックで世界を旅する",
      category: "travel",
      difficulty: "high",
      risk_level: "medium",
      status: "planned",
      value_statement: "視野を広げ、人生を豊かにする",
      cost_estimate: 1000000,
      target_year: user.birth_year + time_bucket.start_age + 2
    }
  end
  
  let(:invalid_attributes) do
    {
      title: "",
      category: "invalid_category",
      status: "invalid_status",
      value_statement: ""
    }
  end

  describe "GET /v1/time_buckets/:time_bucket_id/bucket_items" do
    context "when authenticated" do
      before do
        create_list(:bucket_item, 3, time_bucket: time_bucket)
        create_list(:bucket_item, 2, time_bucket: other_time_bucket)
      end
      
      it "returns bucket items for the time bucket" do
        get "/v1/time_buckets/#{time_bucket.id}/bucket_items", headers: auth_headers(session)
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json.length).to eq(3)
      end
    end
    
    context "when accessing other user's time bucket" do
      it "returns 404" do
        get "/v1/time_buckets/#{other_time_bucket.id}/bucket_items", headers: auth_headers(session)
        expect(response).to have_http_status(:not_found)
      end
    end
    
    context "when not authenticated" do
      it "returns 401" do
        get "/v1/time_buckets/#{time_bucket.id}/bucket_items"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /v1/bucket_items/:id" do
    let(:bucket_item) { create(:bucket_item, time_bucket: time_bucket) }
    
    context "when authenticated" do
      it "returns the bucket item" do
        get "/v1/bucket_items/#{bucket_item.id}", headers: auth_headers(session)
        
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['id']).to eq(bucket_item.id)
        expect(json['title']).to eq(bucket_item.title)
      end
    end
    
    context "when accessing other user's bucket item" do
      let(:other_item) { create(:bucket_item, time_bucket: other_time_bucket) }
      
      it "returns 404" do
        get "/v1/bucket_items/#{other_item.id}", headers: auth_headers(session)
        expect(response).to have_http_status(:not_found)
      end
    end
    
    context "when not authenticated" do
      it "returns 401" do
        get "/v1/bucket_items/#{bucket_item.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /v1/time_buckets/:time_bucket_id/bucket_items" do
    context "with valid parameters" do
      it "creates a new bucket item" do
        expect {
          post "/v1/time_buckets/#{time_bucket.id}/bucket_items",
               params: { bucket_item: valid_attributes },
               headers: auth_headers(session)
        }.to change(BucketItem, :count).by(1)
        
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['title']).to eq(valid_attributes[:title])
      end
    end
    
    context "with invalid parameters" do
      it "returns unprocessable entity" do
        post "/v1/time_buckets/#{time_bucket.id}/bucket_items",
             params: { bucket_item: invalid_attributes },
             headers: auth_headers(session)
        
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end
    
    context "when not authenticated" do
      it "returns 401" do
        post "/v1/time_buckets/#{time_bucket.id}/bucket_items",
             params: { bucket_item: valid_attributes }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PATCH /v1/bucket_items/:id" do
    let(:bucket_item) { create(:bucket_item, time_bucket: time_bucket) }
    let(:new_attributes) { { title: "Updated Title", status: "in_progress" } }
    
    context "with valid parameters" do
      it "updates the bucket item" do
        patch "/v1/bucket_items/#{bucket_item.id}",
              params: { bucket_item: new_attributes },
              headers: auth_headers(session)
        
        expect(response).to have_http_status(:success)
        bucket_item.reload
        expect(bucket_item.title).to eq("Updated Title")
        expect(bucket_item.status).to eq("in_progress")
      end
    end
    
    context "with invalid parameters" do
      it "returns unprocessable entity" do
        patch "/v1/bucket_items/#{bucket_item.id}",
              params: { bucket_item: { title: "", category: "invalid" } },
              headers: auth_headers(session)
        
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
    
    context "when accessing other user's bucket item" do
      let(:other_item) { create(:bucket_item, time_bucket: other_time_bucket) }
      
      it "returns 404" do
        patch "/v1/bucket_items/#{other_item.id}",
              params: { bucket_item: new_attributes },
              headers: auth_headers(session)
        
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /v1/bucket_items/:id/complete" do
    let(:bucket_item) { create(:bucket_item, time_bucket: time_bucket, status: "in_progress") }
    
    context "when authenticated" do
      it "marks the item as done" do
        patch "/v1/bucket_items/#{bucket_item.id}/complete", headers: auth_headers(session)
        
        expect(response).to have_http_status(:success)
        bucket_item.reload
        expect(bucket_item.status).to eq("done")
        expect(bucket_item.completed_at).to be_present
      end
    end
    
    context "when accessing other user's bucket item" do
      let(:other_item) { create(:bucket_item, time_bucket: other_time_bucket) }
      
      it "returns 404" do
        patch "/v1/bucket_items/#{other_item.id}/complete", headers: auth_headers(session)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /v1/bucket_items/:id" do
    let!(:bucket_item) { create(:bucket_item, time_bucket: time_bucket) }
    
    context "when authenticated" do
      it "destroys the bucket item" do
        expect {
          delete "/v1/bucket_items/#{bucket_item.id}", headers: auth_headers(session)
        }.to change(BucketItem, :count).by(-1)
        
        expect(response).to have_http_status(:no_content)
      end
    end
    
    context "when accessing other user's bucket item" do
      let!(:other_item) { create(:bucket_item, time_bucket: other_time_bucket) }
      
      it "returns 404" do
        expect {
          delete "/v1/bucket_items/#{other_item.id}", headers: auth_headers(session)
        }.not_to change(BucketItem, :count)
        
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
