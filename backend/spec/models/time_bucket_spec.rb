require 'rails_helper'

RSpec.describe TimeBucket, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:bucket_items).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:time_bucket) }

    it { should validate_presence_of(:label) }
    it { should validate_presence_of(:start_age) }
    it { should validate_presence_of(:end_age) }
    it { should validate_presence_of(:granularity) }
    it { should validate_presence_of(:position) }

    it { should validate_numericality_of(:start_age).is_greater_than_or_equal_to(20).is_less_than_or_equal_to(100) }
    it { should validate_numericality_of(:end_age).is_greater_than_or_equal_to(20).is_less_than_or_equal_to(100) }
    it { should validate_numericality_of(:position).only_integer.is_greater_than_or_equal_to(0) }

    it { should validate_inclusion_of(:granularity).in_array(%w[5y 10y]) }

    context 'end_age validation' do
      it 'is invalid when end_age is less than start_age' do
        bucket = build(:time_bucket, start_age: 30, end_age: 25)
        expect(bucket).not_to be_valid
        expect(bucket.errors[:end_age]).to include('must be greater than start_age')
      end

      it 'is valid when end_age equals start_age' do
        bucket = build(:time_bucket, start_age: 100, end_age: 100)
        expect(bucket).to be_valid
      end

      it 'is valid when end_age is greater than start_age' do
        bucket = build(:time_bucket, start_age: 30, end_age: 39)
        expect(bucket).to be_valid
      end
    end

    context 'overlapping buckets validation' do
      let(:user) { create(:user) }

      it 'is invalid when bucket overlaps with existing bucket' do
        create(:time_bucket, user: user, start_age: 20, end_age: 29)
        overlapping_bucket = build(:time_bucket, user: user, start_age: 25, end_age: 34)
        expect(overlapping_bucket).not_to be_valid
        expect(overlapping_bucket.errors[:base]).to be_present
      end

      it 'is valid when buckets do not overlap' do
        create(:time_bucket, user: user, start_age: 20, end_age: 29)
        non_overlapping_bucket = build(:time_bucket, user: user, start_age: 30, end_age: 39)
        expect(non_overlapping_bucket).to be_valid
      end

      it 'allows same age ranges for different users' do
        user1 = create(:user)
        user2 = create(:user)
        create(:time_bucket, user: user1, start_age: 20, end_age: 29)
        same_range_bucket = build(:time_bucket, user: user2, start_age: 20, end_age: 29)
        expect(same_range_bucket).to be_valid
      end
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    
    describe '.ordered' do
      it 'returns buckets in position order' do
        bucket3 = create(:time_bucket, user: user, position: 3, start_age: 40, end_age: 49)
        bucket1 = create(:time_bucket, user: user, position: 1, start_age: 20, end_age: 29)
        bucket2 = create(:time_bucket, user: user, position: 2, start_age: 30, end_age: 39)
        
        expect(TimeBucket.ordered).to eq([bucket1, bucket2, bucket3])
      end
    end

    describe '.by_age_range' do
      it 'returns buckets that include the specified age' do
        bucket_20s = create(:time_bucket, user: user, start_age: 20, end_age: 29)
        bucket_30s = create(:time_bucket, user: user, start_age: 30, end_age: 39)
        
        expect(TimeBucket.by_age_range(25)).to include(bucket_20s)
        expect(TimeBucket.by_age_range(25)).not_to include(bucket_30s)
      end
    end
  end
end
