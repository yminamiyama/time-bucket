require 'rails_helper'

RSpec.describe "Api::V1::Dashboard Review Completed", type: :request do
  let(:user) { create(:user, birthdate: Date.new(1990, 6, 15)) }
  let(:session) { create(:session, user: user) }
  let!(:bucket_20s) { create(:time_bucket, user: user, label: "20s", start_age: 20, end_age: 29) }
  let!(:bucket_30s) { create(:time_bucket, user: user, label: "30s", start_age: 30, end_age: 39) }
  let!(:bucket_40s) { create(:time_bucket, user: user, label: "40s", start_age: 40, end_age: 49) }

  describe "GET /v1/dashboard/review-completed" do
    context "when user has no completed items" do
      it "returns empty completion data" do
        get "/v1/dashboard/review-completed", headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json["total_completed"]).to eq(0)
        expect(json["total_cost"]).to eq(0)
        expect(json["items"]).to eq([])
        expect(json["category_achievements"]).to be_an(Array)
        expect(json["bucket_completions"]).to be_an(Array)
      end
    end

    context "when user has completed items across categories" do
      before do
        birth_year = user.birthdate.year
        # Completed items in different categories
        # bucket_20s: ages 20-29, so years birth_year+20 to birth_year+29
        create(:bucket_item, time_bucket: bucket_20s, status: 'done', category: 'travel', cost_estimate: 50000, target_year: birth_year + 25, completed_at: Date.new(birth_year + 25, 3, 1))
        create(:bucket_item, time_bucket: bucket_20s, status: 'done', category: 'learning', cost_estimate: 30000, target_year: birth_year + 27, completed_at: Date.new(birth_year + 27, 5, 1))
        # bucket_30s: ages 30-39
        create(:bucket_item, time_bucket: bucket_30s, status: 'done', category: 'family', cost_estimate: 100000, target_year: birth_year + 35, completed_at: Date.new(birth_year + 35, 1, 1))
        
        # Non-completed items
        create(:bucket_item, time_bucket: bucket_30s, status: 'planned', category: 'travel', cost_estimate: 200000, target_year: birth_year + 38)
        create(:bucket_item, time_bucket: bucket_40s, status: 'in_progress', category: 'learning', cost_estimate: 150000, target_year: birth_year + 45)
      end

      it "returns correct completion stats and cost" do
        get "/v1/dashboard/review-completed", headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json["total_completed"]).to eq(3)
        expect(json["total_cost"]).to eq(180000)
        expect(json["items"].length).to eq(3)
      end

      it "calculates category-wise achievement rates correctly" do
        get "/v1/dashboard/review-completed", headers: auth_headers(session)

        json = JSON.parse(response.body)
        category_achievements = json["category_achievements"]

        travel = category_achievements.find { |c| c["category"] == "travel" }
        expect(travel["total"]).to eq(2) # 1 done + 1 planned
        expect(travel["completed"]).to eq(1)
        expect(travel["achievement_rate"]).to eq(50.0)

        learning = category_achievements.find { |c| c["category"] == "learning" }
        expect(learning["total"]).to eq(2) # 1 done + 1 in_progress
        expect(learning["completed"]).to eq(1)
        expect(learning["achievement_rate"]).to eq(50.0)

        family = category_achievements.find { |c| c["category"] == "family" }
        expect(family["total"]).to eq(1)
        expect(family["completed"]).to eq(1)
        expect(family["achievement_rate"]).to eq(100.0)
      end

      it "includes bucket-wise completion data with cumulative costs" do
        get "/v1/dashboard/review-completed", headers: auth_headers(session)

        json = JSON.parse(response.body)
        bucket_completions = json["bucket_completions"]

        bucket_20s_data = bucket_completions.find { |b| b["bucket_id"] == bucket_20s.id }
        expect(bucket_20s_data["label"]).to eq("20s")
        expect(bucket_20s_data["completed_count"]).to eq(2)
        expect(bucket_20s_data["total_count"]).to eq(2)
        expect(bucket_20s_data["cumulative_cost"]).to eq(80000)
        expect(bucket_20s_data["completion_rate"]).to eq(100.0)

        bucket_30s_data = bucket_completions.find { |b| b["bucket_id"] == bucket_30s.id }
        expect(bucket_30s_data["completed_count"]).to eq(1)
        expect(bucket_30s_data["total_count"]).to eq(2)
        expect(bucket_30s_data["cumulative_cost"]).to eq(100000)
        expect(bucket_30s_data["completion_rate"]).to eq(50.0)

        bucket_40s_data = bucket_completions.find { |b| b["bucket_id"] == bucket_40s.id }
        expect(bucket_40s_data["completed_count"]).to eq(0)
        expect(bucket_40s_data["total_count"]).to eq(1)
        expect(bucket_40s_data["cumulative_cost"]).to eq(0)
        expect(bucket_40s_data["completion_rate"]).to eq(0.0)
      end

      it "returns completed items with correct attributes" do
        get "/v1/dashboard/review-completed", headers: auth_headers(session)

        json = JSON.parse(response.body)
        items = json["items"]

        expect(items.length).to eq(3)
        
        first_item = items.first
        expect(first_item).to have_key("id")
        expect(first_item).to have_key("title")
        expect(first_item).to have_key("category")
        expect(first_item).to have_key("cost_estimate")
        expect(first_item).to have_key("target_year")
        expect(first_item).to have_key("bucket_label")
        expect(first_item).to have_key("bucket_age_range")
        
        # Verify bucket_age_range format
        expect(first_item["bucket_age_range"]).to match(/\d+-\d+/)
      end
    end

    context "when category has zero items" do
      before do
        birth_year = user.birthdate.year
        create(:bucket_item, time_bucket: bucket_20s, status: 'done', category: 'travel', cost_estimate: 50000, target_year: birth_year + 25, completed_at: Date.new(birth_year + 25, 1, 1))
      end

      it "returns 0 achievement rate for categories with no items" do
        get "/v1/dashboard/review-completed", headers: auth_headers(session)

        json = JSON.parse(response.body)
        category_achievements = json["category_achievements"]

        learning = category_achievements.find { |c| c["category"] == "learning" }
        expect(learning["total"]).to eq(0)
        expect(learning["completed"]).to eq(0)
        expect(learning["achievement_rate"]).to eq(0.0)
      end
    end

    context "when user isolation is required" do
      let(:other_user) { create(:user, birthdate: Date.new(1985, 3, 20)) }
      let(:other_bucket) { create(:time_bucket, user: other_user, label: "Other", start_age: 30, end_age: 39) }

      before do
        user_birth_year = user.birthdate.year
        other_birth_year = other_user.birthdate.year
        create(:bucket_item, time_bucket: bucket_20s, status: 'done', category: 'travel', cost_estimate: 50000, target_year: user_birth_year + 25, completed_at: Date.new(user_birth_year + 25, 1, 1))
        create(:bucket_item, time_bucket: other_bucket, status: 'done', category: 'travel', cost_estimate: 100000, target_year: other_birth_year + 35, completed_at: Date.new(other_birth_year + 35, 6, 1))
      end

      it "returns only current user's completed items" do
        get "/v1/dashboard/review-completed", headers: auth_headers(session)

        json = JSON.parse(response.body)
        
        expect(json["total_completed"]).to eq(1)
        expect(json["total_cost"]).to eq(50000)
        expect(json["items"].length).to eq(1)
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        get "/v1/dashboard/review-completed"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
