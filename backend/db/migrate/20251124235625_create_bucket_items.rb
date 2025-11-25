class CreateBucketItems < ActiveRecord::Migration[8.1]
  def change
    create_table :bucket_items, id: :uuid do |t|
      t.references :time_bucket, null: false, foreign_key: true, type: :uuid
      t.string :title, null: false
      t.text :description
      t.string :category, null: false
      t.string :difficulty
      t.string :risk_level
      t.integer :cost_estimate, default: 0
      t.string :status, null: false, default: 'planned'
      t.integer :target_year
      t.text :value_statement, null: false
      t.string :tags, array: true, default: []
      t.jsonb :notes, default: {}
      t.datetime :completed_at

      t.timestamps
    end

    add_index :bucket_items, :status
    add_index :bucket_items, :target_year
    add_index :bucket_items, :category
  end
end
