require 'rails_helper'

RSpec.describe "Api::V1::NotificationSettings", type: :request do
  let(:user) { create(:user) }
  let(:session) { create(:session, user: user) }

  describe "GET /v1/notification-settings" do
    context "when user has no settings yet" do
      it "returns default notification settings" do
        get "/v1/notification-settings", headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json["email_enabled"]).to eq(true)
        expect(json["slack_webhook_url"]).to be_nil
        expect(json["digest_time"]).to eq("09:00")
        expect(json["events"]).to eq({})
      end
    end

    context "when user has existing settings" do
      before do
        user.notification_preference&.destroy
        user.create_notification_preference!(
          email_enabled: false,
          slack_webhook_url: "https://hooks.slack.com/test",
          digest_time: "18:00",
          events: { "bucket_item_due" => true, "weekly_digest" => false }
        )
      end

      it "returns user's notification settings" do
        get "/v1/notification-settings", headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json["email_enabled"]).to eq(false)
        expect(json["slack_webhook_url"]).to eq("https://hooks.slack.com/test")
        expect(json["digest_time"]).to eq("18:00")
        expect(json["events"]["bucket_item_due"]).to be_truthy
        expect(json["events"]["weekly_digest"]).to be_falsy
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        get "/v1/notification-settings"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PATCH /v1/notification-settings" do
    context "when updating email_enabled" do
      it "updates email notification preference" do
        patch "/v1/notification-settings", 
              params: { email_enabled: false },
              headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json["email_enabled"]).to eq(false)
        expect(user.notification_preference.reload.email_enabled).to eq(false)
      end
    end

    context "when updating slack_webhook_url" do
      it "updates slack webhook URL" do
        patch "/v1/notification-settings", 
              params: { slack_webhook_url: "https://hooks.slack.com/services/test" },
              headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json["slack_webhook_url"]).to eq("https://hooks.slack.com/services/test")
      end

      it "rejects invalid URL format" do
        patch "/v1/notification-settings", 
              params: { slack_webhook_url: "not-a-valid-url" },
              headers: auth_headers(session)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        
        expect(json["errors"]).to include(match(/must be a valid URL/))
      end
    end

    context "when updating digest_time" do
      it "updates digest time" do
        patch "/v1/notification-settings", 
              params: { digest_time: "14:30" },
              headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json["digest_time"]).to eq("14:30")
      end

      it "rejects invalid time format" do
        patch "/v1/notification-settings", 
              params: { digest_time: "25:00" },
              headers: auth_headers(session)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        
        expect(json["errors"]).to include(match(/must be in HH:MM format/))
      end

      it "rejects invalid time format with letters" do
        patch "/v1/notification-settings", 
              params: { digest_time: "noon" },
              headers: auth_headers(session)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when updating event preferences" do
      it "updates event notification preferences" do
        patch "/v1/notification-settings", 
              params: { events: { bucket_item_due: true, weekly_digest: false, completion_reminder: true } },
              headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json["events"]["bucket_item_due"]).to be_truthy
        expect(json["events"]["weekly_digest"]).to eq("false")
        expect(json["events"]["completion_reminder"]).to be_truthy
      end
    end

    context "when updating multiple fields at once" do
      it "updates all specified fields" do
        patch "/v1/notification-settings", 
              params: { 
                email_enabled: false,
                slack_webhook_url: "https://hooks.slack.com/new",
                digest_time: "08:30",
                events: { bucket_item_due: true }
              },
              headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json["email_enabled"]).to eq(false)
        expect(json["slack_webhook_url"]).to eq("https://hooks.slack.com/new")
        expect(json["digest_time"]).to eq("08:30")
        expect(json["events"]["bucket_item_due"]).to be_truthy
      end
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        patch "/v1/notification-settings", 
              params: { email_enabled: false }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when clearing slack_webhook_url" do
      before do
        user.notification_preference&.destroy
        user.create_notification_preference!(
          slack_webhook_url: "https://hooks.slack.com/test"
        )
      end

      it "allows clearing the webhook URL" do
        patch "/v1/notification-settings", 
              params: { slack_webhook_url: "" },
              headers: auth_headers(session)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        
        expect(json["slack_webhook_url"]).to be_blank
      end
    end
  end
end
