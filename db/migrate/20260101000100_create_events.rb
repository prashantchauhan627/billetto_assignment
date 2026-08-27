class CreateEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :events do |t|
      t.string :billetto_id, null: false
      t.string :title, null: false
      t.text :description
      t.string :url
      t.string :image_url
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.string :city
      t.string :organiser_name
      t.string :category

      t.timestamps
    end

    # Lets the importer upsert instead of duplicating on every run.
    add_index :events, :billetto_id, unique: true
    add_index :events, :starts_at
  end
end
