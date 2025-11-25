FactoryBot.define do
  factory :time_bucket do
    user
    sequence(:label) { |n| "Bucket #{n}" }
    start_age { 20 }
    end_age { 29 }
    granularity { '10y' }
    description { 'A time bucket for planning life goals' }
    sequence(:position) { |n| n }

    trait :thirties do
      label { '30-39' }
      start_age { 30 }
      end_age { 39 }
    end

    trait :five_year do
      granularity { '5y' }
      start_age { 20 }
      end_age { 24 }
    end

    trait :ten_year do
      granularity { '10y' }
      start_age { 20 }
      end_age { 29 }
    end
  end
end
