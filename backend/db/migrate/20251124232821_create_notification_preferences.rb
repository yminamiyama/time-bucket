class CreateNotificationPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_preferences, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.boolean :email_enabled, default: true
      t.string :slack_webhook_url
      t.string :digest_time, default: '09:00'
      t.jsonb :events, default: {}

      t.timestamps
    end
  end
end
