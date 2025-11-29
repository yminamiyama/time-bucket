require 'rails_helper'

RSpec.describe "Api::V1::Profile", type: :request do
  let(:user) { create(:user, birthdate: Date.new(1990, 5, 15), timezone: "Asia/Tokyo") }
  let(:session) { create(:session, user: user) }

  describe "GET /api/v1/profile" do
    it "returns current user's profile" do
      get "/api/v1/profile", headers: auth_headers(session)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      
      expect(body["id"]).to eq(user.id)
      expect(body["email"]).to eq(user.email)
      expect(body["birthdate"]).to eq("1990-05-15")
      expect(body["current_age"]).to be_present
      expect(body["timezone"]).to eq("Asia/Tokyo")
      expect(body["provider"]).to eq("google_oauth2")
    end

    it "returns unauthorized when not authenticated" do
      get "/api/v1/profile"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/profile" do
    context "with valid parameters" do
      it "updates birthdate and recalculates age" do
        new_birthdate = Date.new(1985, 3, 20)
        
        patch "/api/v1/profile", 
              params: { profile: { birthdate: new_birthdate } },
              headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        
        expect(body["birthdate"]).to eq("1985-03-20")
        
        # Calculate expected age correctly (account for birthday not yet occurred this year)
        expected_age = Date.today.year - 1985
        expected_age -= 1 if Date.today < Date.new(Date.today.year, 3, 20)
        expect(body["current_age"]).to eq(expected_age)
        
        user.reload
        expect(user.birthdate).to eq(new_birthdate)
      end

      it "updates timezone" do
        patch "/api/v1/profile", 
              params: { profile: { timezone: "America/New_York" } },
              headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        
        expect(body["timezone"]).to eq("America/New_York")
        
        user.reload
        expect(user.timezone).to eq("America/New_York")
      end

      it "updates values_tags" do
        new_tags = { "adventure" => "true", "family" => "true" }
        
        patch "/api/v1/profile", 
              params: { profile: { values_tags: new_tags } },
              headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        
        expect(body["values_tags"]).to eq(new_tags)
        
        user.reload
        expect(user.values_tags).to eq(new_tags)
      end
    end

    context "with invalid parameters" do
      it "returns error for invalid birthdate (too young)" do
        patch "/api/v1/profile", 
              params: { profile: { birthdate: 10.years.ago.to_date } },
              headers: auth_headers(session)

        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        
        expect(body["errors"]).to be_present
        expect(body["errors"].first).to include("Birthdate")
      end

      it "returns error for invalid birthdate (too old)" do
        patch "/api/v1/profile", 
              params: { profile: { birthdate: 120.years.ago.to_date } },
              headers: auth_headers(session)

        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        
        expect(body["errors"]).to be_present
        expect(body["errors"].first).to include("Birthdate")
      end

      it "returns error for blank birthdate" do
        patch "/api/v1/profile", 
              params: { profile: { birthdate: nil } },
              headers: auth_headers(session)

        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        
        expect(body["errors"]).to be_present
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        patch "/api/v1/profile", 
              params: { profile: { birthdate: Date.new(1985, 3, 20) } }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when updating only specific fields" do
      it "updates only birthdate without affecting other fields" do
        original_timezone = user.timezone
        new_birthdate = Date.new(1988, 7, 10)
        
        patch "/api/v1/profile", 
              params: { profile: { birthdate: new_birthdate } },
              headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        
        user.reload
        expect(user.birthdate).to eq(new_birthdate)
        expect(user.timezone).to eq(original_timezone)
      end
    end
  end
end
