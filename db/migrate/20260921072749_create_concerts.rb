class CreateConcerts < ActiveRecord::Migration[8.1]
  def change
    create_table :concerts do |t|
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      # description and setlist are required from publication onwards only, so the rule lives
      # in the model instead of a NOT NULL constraint. See docs/datenmodell.md, section 2.
      t.text :description
      t.text :setlist
      t.string :playlist_url
      t.integer :capacity, null: false
      t.string :status, null: false, default: "draft"
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :lock_version, null: false, default: 0

      t.timestamps

      t.check_constraint "capacity > 0", name: "concerts_capacity_positive"
      t.check_constraint "ends_at > starts_at", name: "concerts_end_after_start"
      t.check_constraint "status IN ('draft', 'published', 'cancelled')", name: "concerts_status_valid"
    end

    add_index :concerts, [ :status, :starts_at ]
  end
end
