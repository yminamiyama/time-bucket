require 'rails_helper'

RSpec.describe "Api::V1::Dashboard Actions Now", type: :request do
  let(:user) { create(:user, birthdate: Date.new(1990, 1, 1)) }
  let(:session) { create(:session, user: user) }

  describe "GET /v1/dashboard/actions-now" do
    context "when user has no bucket items" do
      it "returns empty items array with metadata" do
        get "/v1/dashboard/actions-now", headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        
        expect(body["current_age"]).to be_present
        expect(body["current_year"]).to eq(Date.today.year)
        expect(body["threshold_years"]).to eq(5)
        expect(body["items"]).to eq([])
      end
    end

    context "when user has bucket items with various target years" do
      let!(:bucket_past) { create(:time_bucket, user: user, start_age: 20, end_age: 29) }
      let!(:bucket_now) { create(:time_bucket, user: user, start_age: 30, end_age: 39) }
      let!(:bucket_future) { create(:time_bucket, user: user, start_age: 40, end_age: 49) }

      let(:current_year) { Date.today.year }
      
      # Overdue item (user born 1990, bucket 20-29 = 2010-2019)
      let!(:overdue_item) do
        create(:bucket_item, 
               time_bucket: bucket_past, 
               title: "Overdue task",
               target_year: 2018,  # Within bucket range, overdue
               status: :planned)
      end

      # Approaching item within 5 years (bucket 30-39 = 2020-2029)
      let!(:approaching_item) do
        create(:bucket_item, 
               time_bucket: bucket_now, 
               title: "Upcoming task",
               target_year: [current_year + 3, 2029].min,  # 3 years from now, within bucket range
               status: :in_progress)
      end

      # Item exactly at threshold (5 years)
      let!(:threshold_item) do
        create(:bucket_item, 
               time_bucket: bucket_future, 
               title: "Threshold task",
               target_year: [current_year + 5, 2039].min,  # 5 years from now, within bucket range
               status: :planned)
      end

      # Far future item (beyond 5 years, bucket 40-49 = 2030-2039)
      let!(:far_future_item) do
        create(:bucket_item, 
               time_bucket: bucket_future, 
               title: "Future task",
               target_year: [current_year + 11, 2039].min,  # 11 years from now, within bucket range
               status: :planned)
      end

      # Completed item (should not appear)
      let!(:completed_item) do
        create(:bucket_item, :done,
               time_bucket: bucket_past, 
               title: "Completed task",
               target_year: 2015)
      end

      it "returns only overdue and approaching items, sorted by years_until" do
        get "/v1/dashboard/actions-now", headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        
        expect(body["items"].length).to eq(3)
        
        # Check sorting: overdue first, then approaching
        expect(body["items"][0]["id"]).to eq(overdue_item.id)
        expect(body["items"][0]["reason"]).to eq("overdue")
        expect(body["items"][0]["years_until"]).to be < 0
        
        expect(body["items"][1]["id"]).to eq(approaching_item.id)
        expect(body["items"][1]["reason"]).to eq("approaching")
        
        expect(body["items"][2]["id"]).to eq(threshold_item.id)
        expect(body["items"][2]["reason"]).to eq("approaching")
      end

      it "includes all required fields for each item" do
        get "/v1/dashboard/actions-now", headers: auth_headers(session)

        body = JSON.parse(response.body)
        item = body["items"].first
        
        expect(item).to include(
          "id",
          "title",
          "category",
          "difficulty",
          "risk_level",
          "target_year",
          "bucket_label",
          "status",
          "reason",
          "years_until"
        )
        
        expect(item["bucket_label"]).to eq(overdue_item.time_bucket.label)
      end
    end

    context "when multiple users exist" do
      let(:other_user) { create(:user, birthdate: Date.new(1985, 6, 15)) }
      let!(:other_bucket) { create(:time_bucket, user: other_user, start_age: 35, end_age: 44) }
      let!(:other_item) do
        create(:bucket_item, 
               time_bucket: other_bucket, 
               title: "Other user task",
               target_year: [Date.today.year - 4, 2020].max,  # Overdue, within bucket range (1985 + 35 = 2020 to 2029)
               status: :planned)
      end

      let!(:my_bucket) { create(:time_bucket, user: user, start_age: 30, end_age: 39) }
      let!(:my_item) do
        create(:bucket_item, 
               time_bucket: my_bucket, 
               title: "My task",
               target_year: [Date.today.year - 3, 2020].max,  # Overdue, within bucket range (1990 + 30 = 2020 to 2029)
               status: :planned)
      end

      it "returns only current user's items" do
        get "/v1/dashboard/actions-now", headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        
        expect(body["items"].length).to eq(1)
        expect(body["items"][0]["id"]).to eq(my_item.id)
        expect(body["items"][0]["title"]).to eq("My task")
      end
    end

    context "when not authenticated" do
      it "returns unauthorized error" do
        get "/v1/dashboard/actions-now"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
