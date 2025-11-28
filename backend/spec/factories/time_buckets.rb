FactoryBot.define do
  factory :time_bucket do
    user
    sequence(:label) { |n| "Bucket #{n}" }
    # Generate non-overlapping age ranges: 20-29, 30-39, 40-49, 50-59, 60-69, 70-79, 80-89
    sequence(:start_age) { |n| [20, 30, 40, 50, 60, 70, 80, 90][(n - 1) % 8] }
    sequence(:end_age) { |n| [29, 39, 49, 59, 69, 79, 89, 99][(n - 1) % 8] }
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
