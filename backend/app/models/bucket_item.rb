class BucketItem < ApplicationRecord
  CATEGORIES = %w[travel career family finance health learning other].freeze
  DIFFICULTIES = %w[low medium high].freeze
  RISK_LEVELS = %w[low medium high].freeze
  STATUSES = %w[planned in_progress done].freeze

  belongs_to :time_bucket

  validates :title, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :difficulty, inclusion: { in: DIFFICULTIES }, allow_nil: true
  validates :risk_level, inclusion: { in: RISK_LEVELS }, allow_nil: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :value_statement, presence: true
  validates :cost_estimate, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  
  validate :target_year_within_bucket_range
  validate :completed_at_required_when_done

  scope :by_status, ->(status) { where(status: status) }
  scope :by_category, ->(category) { where(category: category) }
  scope :upcoming, -> { where('target_year IS NOT NULL AND target_year <= ?', Date.today.year + 5).where.not(status: 'done') }
  scope :completed, -> { where(status: 'done') }

  def user
    time_bucket&.user
  end

  private

  def target_year_within_bucket_range
    return unless time_bucket && target_year

    user = time_bucket.user
    return unless user&.birth_year

    min_year = user.birth_year + time_bucket.start_age
    max_year = user.birth_year + time_bucket.end_age

    unless target_year.between?(min_year, max_year)
      errors.add(:target_year, "must be between #{min_year} and #{max_year} for this bucket")
    end
  end

  def completed_at_required_when_done
    if status == 'done' && completed_at.blank?
      errors.add(:completed_at, "can't be blank when status is done")
    end
  end
end
