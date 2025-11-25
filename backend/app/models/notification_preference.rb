class NotificationPreference < ApplicationRecord
  belongs_to :user

  validates :user, presence: true, uniqueness: true
  validates :digest_time, format: { with: /\A([01]\d|2[0-3]):([0-5]\d)\z/, message: "must be in HH:MM format" }, allow_blank: true
  validates :slack_webhook_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true
end
