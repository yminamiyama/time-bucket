require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:time_buckets).dependent(:destroy) }
    it { should have_one(:notification_preference).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid_email').for(:email) }

    it { should validate_presence_of(:birthdate) }
    it { should validate_presence_of(:timezone) }

    context 'with OAuth' do
      it 'requires provider when uid is present' do
        user = build(:user, provider: nil, uid: 'some_uid')
        expect(user).not_to be_valid
        expect(user.errors[:provider]).to include("can't be blank")
      end

      it 'requires uid when provider is present' do
        user = build(:user, provider: 'google_oauth2', uid: nil)
        expect(user).not_to be_valid
        expect(user.errors[:uid]).to include("can't be blank")
      end

      it 'validates uniqueness of uid scoped to provider' do
        create(:user, provider: 'google_oauth2', uid: 'unique_uid')
        duplicate_user = build(:user, provider: 'google_oauth2', uid: 'unique_uid')
        expect(duplicate_user).not_to be_valid
      end
    end

    context 'birthdate validation' do
      it 'is valid with birthdate 20 years ago' do
        user = build(:user, birthdate: 20.years.ago.to_date)
        expect(user).to be_valid
      end

      it 'is valid with birthdate 100 years ago' do
        user = build(:user, birthdate: 100.years.ago.to_date)
        expect(user).to be_valid
      end

      it 'is invalid with birthdate less than 20 years ago' do
        user = build(:user, birthdate: 19.years.ago.to_date)
        expect(user).not_to be_valid
        expect(user.errors[:birthdate]).to be_present
      end

      it 'is invalid with birthdate more than 100 years ago' do
        user = build(:user, birthdate: 101.years.ago.to_date)
        expect(user).not_to be_valid
        expect(user.errors[:birthdate]).to be_present
      end
    end
  end

  describe 'callbacks' do
    it 'creates notification_preference after user creation' do
      user = create(:user)
      expect(user.notification_preference).to be_present
    end
  end

  describe '#current_age' do
    it 'calculates age correctly for a 30-year-old user' do
      user = create(:user, birthdate: 30.years.ago.to_date)
      expect(user.current_age).to eq(30)
    end

    it 'calculates age correctly before birthday this year' do
      user = create(:user, birthdate: Date.new(1995, 12, 31))
      allow(Date).to receive(:today).and_return(Date.new(2025, 1, 1))
      expect(user.current_age).to eq(29)
    end

    it 'calculates age correctly after birthday this year' do
      user = create(:user, birthdate: Date.new(1995, 1, 1))
      allow(Date).to receive(:today).and_return(Date.new(2025, 12, 31))
      expect(user.current_age).to eq(30)
    end

    it 'returns nil when birthdate is nil' do
      user = build(:user, birthdate: nil)
      expect(user.current_age).to be_nil
    end
  end

  describe '#birth_year' do
    it 'returns the year of birthdate' do
      user = create(:user, birthdate: Date.new(1990, 5, 15))
      expect(user.birth_year).to eq(1990)
    end

    it 'returns nil when birthdate is nil' do
      user = build(:user, birthdate: nil)
      expect(user.birth_year).to be_nil
    end
  end
end
