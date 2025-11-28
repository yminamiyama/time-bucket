class TimeBucketTemplateGenerator
  VALID_GRANULARITIES = %w[5y 10y].freeze
  MIN_AGE = 20
  MAX_AGE = 100

  attr_reader :user, :granularity, :errors

  def initialize(user:, granularity:)
    @user = user
    @granularity = granularity
    @errors = []
  end

  def generate
    return false unless valid?

    ActiveRecord::Base.transaction do
      buckets = build_buckets
      buckets.each do |bucket_attrs|
        user.time_buckets.create!(bucket_attrs)
      end
      true
    end
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.message
    false
  end

  private

  def valid?
    validate_granularity
    validate_user_birthdate
    @errors.empty?
  end

  def validate_granularity
    unless VALID_GRANULARITIES.include?(granularity)
      @errors << "Granularity must be one of: #{VALID_GRANULARITIES.join(', ')}"
    end
  end

  def validate_user_birthdate
    unless user.birthdate.present?
      @errors << "User birthdate is required for template generation"
    end
  end

  def build_buckets
    interval = granularity == '5y' ? 5 : 10
    buckets = []
    current_age = MIN_AGE
    
    while current_age <= MAX_AGE
      # Calculate the natural end age for this interval
      natural_end = current_age + interval - 1
      
      # If we're close to MAX_AGE (within interval), extend to MAX_AGE
      if natural_end >= MAX_AGE || (MAX_AGE - natural_end) < interval
        end_age = MAX_AGE
      else
        end_age = natural_end
      end
      
      buckets << {
        label: "#{current_age}-#{end_age}歳",
        start_age: current_age,
        end_age: end_age,
        granularity: granularity,
        position: buckets.size
      }
      
      break if end_age >= MAX_AGE
      current_age += interval
    end
    
    buckets
  end
end
