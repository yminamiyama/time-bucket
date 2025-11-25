FactoryBot.define do
  factory :notification_preference do
    user
    email_enabled { true }
    slack_webhook_url { nil }
    digest_time { '09:00' }
    events { {} }
  end
end
