class CreateTimeBuckets < ActiveRecord::Migration[8.1]
  def change
    create_table :time_buckets, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :label, null: false
      t.integer :start_age, null: false
      t.integer :end_age, null: false
      t.string :granularity, null: false
      t.text :description
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :time_buckets, [:user_id, :position]
    add_index :time_buckets, [:user_id, :start_age, :end_age]
  end
end
