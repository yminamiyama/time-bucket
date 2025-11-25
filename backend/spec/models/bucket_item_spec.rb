require 'rails_helper'

RSpec.describe BucketItem, type: :model do
  describe 'associations' do
    it { should belong_to(:time_bucket) }
  end

  describe 'validations' do
    subject { build(:bucket_item) }

    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:category) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:value_statement) }

    it { should validate_inclusion_of(:category).in_array(%w[travel career family finance health learning other]) }
    it { should validate_inclusion_of(:difficulty).in_array(%w[low medium high]) }
    it { should validate_inclusion_of(:risk_level).in_array(%w[low medium high]) }
    it { should validate_inclusion_of(:status).in_array(%w[planned in_progress done]) }

    it { should validate_numericality_of(:cost_estimate).only_integer.is_greater_than_or_equal_to(0) }

    context 'target_year validation' do
      let(:user) { create(:user, birthdate: Date.new(1990, 1, 1)) }
      let(:time_bucket) { create(:time_bucket, user: user, start_age: 30, end_age: 39) }

      it 'is valid when target_year is within bucket range' do
        item = build(:bucket_item, time_bucket: time_bucket, target_year: 2020)
        expect(item).to be_valid
      end

      it 'is invalid when target_year is before bucket range' do
        item = build(:bucket_item, time_bucket: time_bucket, target_year: 2015)
        expect(item).not_to be_valid
        expect(item.errors[:target_year]).to be_present
      end

      it 'is invalid when target_year is after bucket range' do
        item = build(:bucket_item, time_bucket: time_bucket, target_year: 2030)
        expect(item).not_to be_valid
        expect(item.errors[:target_year]).to be_present
      end
    end

    context 'completed_at validation' do
      it 'is invalid when status is done but completed_at is blank' do
        item = build(:bucket_item, status: 'done', completed_at: nil)
        expect(item).not_to be_valid
        expect(item.errors[:completed_at]).to include("can't be blank when status is done")
      end

      it 'is valid when status is done and completed_at is present' do
        item = build(:bucket_item, :done)
        expect(item).to be_valid
      end

      it 'is valid when status is not done and completed_at is blank' do
        item = build(:bucket_item, status: 'planned', completed_at: nil)
        expect(item).to be_valid
      end
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:time_bucket) { create(:time_bucket, user: user) }

    describe '.by_status' do
      it 'returns items with specified status' do
        planned_item = create(:bucket_item, time_bucket: time_bucket, status: 'planned')
        done_item = create(:bucket_item, :done, time_bucket: time_bucket)

        expect(BucketItem.by_status('planned')).to include(planned_item)
        expect(BucketItem.by_status('planned')).not_to include(done_item)
      end
    end

    describe '.by_category' do
      it 'returns items with specified category' do
        travel_item = create(:bucket_item, :travel, time_bucket: time_bucket)
        career_item = create(:bucket_item, :career, time_bucket: time_bucket)

        expect(BucketItem.by_category('travel')).to include(travel_item)
        expect(BucketItem.by_category('travel')).not_to include(career_item)
      end
    end

    describe '.upcoming' do
      it 'returns non-done items with target_year within 5 years' do
        # Create user with specific birthdate to control target_year range
        current_year = Date.today.year
        user_with_birthdate = create(:user, birthdate: Date.new(current_year - 35, 1, 1))
        
        # Bucket for ages 35-44, which maps to current_year to current_year+9
        future_bucket = create(:time_bucket, user: user_with_birthdate, start_age: 35, end_age: 44)
        
        upcoming_item = create(:bucket_item, time_bucket: future_bucket, target_year: current_year + 3, status: 'planned')
        far_future_item = create(:bucket_item, time_bucket: future_bucket, target_year: current_year + 9, status: 'planned')
        done_item = create(:bucket_item, :done, time_bucket: future_bucket, target_year: current_year + 1)

        expect(BucketItem.upcoming).to include(upcoming_item)
        expect(BucketItem.upcoming).not_to include(far_future_item)
        expect(BucketItem.upcoming).not_to include(done_item)
      end
    end

    describe '.completed' do
      it 'returns only done items' do
        done_item = create(:bucket_item, :done, time_bucket: time_bucket)
        planned_item = create(:bucket_item, time_bucket: time_bucket, status: 'planned')

        expect(BucketItem.completed).to include(done_item)
        expect(BucketItem.completed).not_to include(planned_item)
      end
    end
  end

  describe '#user' do
    it 'returns the user through time_bucket' do
      user = create(:user)
      time_bucket = create(:time_bucket, user: user)
      item = create(:bucket_item, time_bucket: time_bucket)

      expect(item.user).to eq(user)
    end
  end
end
