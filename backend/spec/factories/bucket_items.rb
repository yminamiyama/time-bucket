FactoryBot.define do
  factory :bucket_item do
    time_bucket
    sequence(:title) { |n| "Bucket Item #{n}" }
    description { 'A meaningful experience to pursue' }
    category { 'travel' }
    difficulty { 'medium' }
    risk_level { 'low' }
    cost_estimate { 1000 }
    status { 'planned' }
    target_year do
      if time_bucket
        time_bucket.user.birth_year + time_bucket.start_age
      else
        Date.today.year + 1
      end
    end
    value_statement { 'This experience aligns with my core values' }
    tags { %w[adventure personal-growth] }
    notes { { reminder: 'Book in advance' } }
    completed_at { nil }

    trait :in_progress do
      status { 'in_progress' }
    end

    trait :done do
      status { 'done' }
      completed_at { 1.week.ago }
    end

    trait :travel do
      category { 'travel' }
      title { 'Visit Japan' }
    end

    trait :career do
      category { 'career' }
      title { 'Get promoted to senior level' }
    end

    trait :high_risk do
      risk_level { 'high' }
    end
  end
end
