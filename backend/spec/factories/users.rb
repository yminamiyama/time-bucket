FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    provider { "google_oauth2" }
    sequence(:uid) { |n| "google_uid_#{n}" }
    birthdate { 30.years.ago.to_date }
    values_tags { {} }
    timezone { "Asia/Tokyo" }

    trait :without_oauth do
      provider { nil }
      uid { nil }
    end

    trait :young do
      birthdate { 20.years.ago.to_date }
    end

    trait :elderly do
      birthdate { 80.years.ago.to_date }
    end
  end
end
