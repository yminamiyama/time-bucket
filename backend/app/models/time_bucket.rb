class TimeBucket < ApplicationRecord
  GRANULARITIES = %w[5y 10y].freeze

  belongs_to :user
  has_many :bucket_items, dependent: :destroy

  validates :label, presence: true
  validates :start_age, presence: true, numericality: { greater_than_or_equal_to: 20, less_than_or_equal_to: 100 }
  validates :end_age, presence: true, numericality: { greater_than_or_equal_to: 20, less_than_or_equal_to: 100 }
  validates :granularity, presence: true, inclusion: { in: GRANULARITIES }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  validate :end_age_greater_than_start_age
  validate :no_overlapping_buckets

  scope :ordered, -> { order(:position) }
  scope :by_age_range, ->(age) { where('start_age <= ? AND end_age >= ?', age, age) }

  private

  def end_age_greater_than_start_age
    return unless start_age && end_age

    if end_age <= start_age
      errors.add(:end_age, "must be greater than start_age")
    end
  end

  def no_overlapping_buckets
    return unless user && start_age && end_age

    overlapping = user.time_buckets
                      .where.not(id: id)
                      .where('start_age <= ? AND end_age >= ?', end_age, start_age)

    if overlapping.exists?
      errors.add(:base, "Time bucket overlaps with existing bucket: #{overlapping.first.label}")
    end
  end
end
