class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    # Enable citext extension for case-insensitive email
    enable_extension 'citext' unless extension_enabled?('citext')
    
    create_table :users, id: :uuid do |t|
      t.citext :email, null: false
      t.string :provider
      t.string :uid
      t.date :birthdate, null: false
      t.jsonb :values_tags, default: {}
      t.string :timezone, default: 'Asia/Tokyo'

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, [:provider, :uid], unique: true, where: "provider IS NOT NULL AND uid IS NOT NULL"
  end
end
