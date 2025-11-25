class AddUniqueIndexToTimeBucketsPosition < ActiveRecord::Migration[8.1]
  def change
    # Remove existing non-unique index
    remove_index :time_buckets, [:user_id, :position]
    
    # Add unique index to ensure each user has unique position values
    add_index :time_buckets, [:user_id, :position], unique: true
  end
end
