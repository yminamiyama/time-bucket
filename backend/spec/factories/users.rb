FactoryBot.define do
  factory :user do
    email { "" }
    provider { "MyString" }
    uid { "MyString" }
    birthdate { "2025-11-24" }
    values_tags { "" }
    timezone { "MyString" }
  end
end
