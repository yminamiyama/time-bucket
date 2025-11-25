require 'rails_helper'

RSpec.describe NotificationPreference, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:user) }
    
    context 'user uniqueness' do
      it 'validates one notification preference per user' do
        user = create(:user)
        # User already has notification_preference via after_create callback
        duplicate_preference = build(:notification_preference, user: user)
        expect(duplicate_preference).not_to be_valid
        expect(duplicate_preference.errors[:user]).to be_present
      end
    end

    context 'digest_time format' do
      it 'is valid with HH:MM format' do
        preference = build(:notification_preference, digest_time: '09:30')
        expect(preference).to be_valid
      end

      it 'is invalid with incorrect format' do
        preference = build(:notification_preference, digest_time: '9:30')
        expect(preference).not_to be_valid
        expect(preference.errors[:digest_time]).to be_present
      end

      it 'is invalid with out of range hours' do
        preference = build(:notification_preference, digest_time: '25:00')
        expect(preference).not_to be_valid
      end

      it 'allows blank digest_time' do
        preference = build(:notification_preference, digest_time: nil)
        expect(preference).to be_valid
      end
    end

    context 'slack_webhook_url validation' do
      it 'is valid with https URL' do
        preference = build(:notification_preference, slack_webhook_url: 'https://hooks.slack.com/services/xxx')
        expect(preference).to be_valid
      end

      it 'is invalid with non-URL string' do
        preference = build(:notification_preference, slack_webhook_url: 'not-a-url')
        expect(preference).not_to be_valid
        expect(preference.errors[:slack_webhook_url]).to be_present
      end

      it 'allows blank slack_webhook_url' do
        preference = build(:notification_preference, slack_webhook_url: nil)
        expect(preference).to be_valid
      end
    end
  end
end
