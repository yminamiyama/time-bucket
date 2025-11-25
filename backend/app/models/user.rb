class User < ApplicationRecord
  # Associations
  has_many :time_buckets, dependent: :destroy
  has_one :notification_preference, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :birthdate, presence: true
  validate :birthdate_within_valid_range
  validates :timezone, presence: true

  # OAuth validations
  validates :provider, presence: true, if: -> { uid.present? }
  validates :uid, presence: true, if: -> { provider.present? }
  validates :uid, uniqueness: { scope: :provider }, if: -> { provider.present? && uid.present? }

  # Callbacks
  after_create :create_default_notification_preference

  # Calculate current age based on birthdate
  def current_age
    return nil unless birthdate

    today = Date.today
    age = today.year - birthdate.year
    age -= 1 if today < birthdate + age.years
    age
  end

  # Birth year for target_year calculations
  def birth_year
    birthdate&.year
  end

  private

  def birthdate_within_valid_range
    return unless birthdate

    min_birthdate = 100.years.ago.to_date
    max_birthdate = 20.years.ago.to_date

    if birthdate < min_birthdate || birthdate > max_birthdate
      errors.add(:birthdate, "must be between #{min_birthdate} and #{max_birthdate}")
    end
  end

  def create_default_notification_preference
    create_notification_preference!
  end
end
