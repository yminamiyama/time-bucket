require 'rails_helper'

RSpec.describe "Api::V1::TimeBucketTemplates", type: :request do
  let(:user) { create(:user) }
  let(:session) { create(:session, user: user) }

  describe "POST /api/v1/time_buckets/templates" do
    context "with 5 year granularity" do
      it "creates time buckets in 5-year intervals" do
        expect {
          post "/api/v1/time_buckets/templates",
               params: { granularity: '5y' },
               headers: auth_headers(session)
        }.to change(TimeBucket, :count).by(16) # 20-24, 25-29, ..., 90-94, 95-100
      end

      it "returns created buckets with correct structure" do
        post "/api/v1/time_buckets/templates",
             params: { granularity: '5y' },
             headers: auth_headers(session)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Time buckets generated successfully')
        expect(json['count']).to eq(16)
        expect(json['buckets']).to be_an(Array)
      end

      it "creates buckets with correct age ranges" do
        post "/api/v1/time_buckets/templates",
             params: { granularity: '5y' },
             headers: auth_headers(session)

        buckets = user.time_buckets.ordered
        expect(buckets.first.start_age).to eq(20)
        expect(buckets.first.end_age).to eq(24)
        expect(buckets.first.label).to eq("20-24歳")
        
        expect(buckets.last.start_age).to eq(95)
        expect(buckets.last.end_age).to eq(100)
        expect(buckets.last.label).to eq("95-100歳")
      end

      it "sets correct granularity" do
        post "/api/v1/time_buckets/templates",
             params: { granularity: '5y' },
             headers: auth_headers(session)

        expect(user.time_buckets.first.granularity).to eq('5y')
      end
    end

    context "with 10 year granularity" do
      it "creates time buckets in 10-year intervals" do
        expect {
          post "/api/v1/time_buckets/templates",
               params: { granularity: '10y' },
               headers: auth_headers(session)
        }.to change(TimeBucket, :count).by(8) # 20-29, 30-39, ..., 80-89, 90-100
      end

      it "creates buckets with correct age ranges" do
        post "/api/v1/time_buckets/templates",
             params: { granularity: '10y' },
             headers: auth_headers(session)

        buckets = user.time_buckets.ordered
        expect(buckets.first.start_age).to eq(20)
        expect(buckets.first.end_age).to eq(29)
        expect(buckets.first.label).to eq("20-29歳")
        
        # Last bucket should be 90-100 (extended to include 100)
        expect(buckets.last.start_age).to eq(90)
        expect(buckets.last.end_age).to eq(100)
        expect(buckets.last.label).to eq("90-100歳")
      end
    end

    context "with invalid granularity" do
      it "returns unprocessable entity" do
        post "/api/v1/time_buckets/templates",
             params: { granularity: 'invalid' },
             headers: auth_headers(session)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
        expect(json['errors'].first).to include('Granularity must be one of')
      end

      it "does not create any buckets" do
        expect {
          post "/api/v1/time_buckets/templates",
               params: { granularity: 'invalid' },
               headers: auth_headers(session)
        }.not_to change(TimeBucket, :count)
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        post "/api/v1/time_buckets/templates",
             params: { granularity: '5y' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user already has buckets" do
      before do
        create(:time_bucket, user: user, start_age: 20, end_age: 29)
      end

      it "fails due to overlapping buckets" do
        post "/api/v1/time_buckets/templates",
             params: { granularity: '5y' },
             headers: auth_headers(session)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end

    context "when buckets are positioned correctly" do
      it "assigns sequential positions" do
        post "/api/v1/time_buckets/templates",
             params: { granularity: '5y' },
             headers: auth_headers(session)

        buckets = user.time_buckets.ordered
        buckets.each_with_index do |bucket, index|
          expect(bucket.position).to eq(index)
        end
      end
    end
  end
end
