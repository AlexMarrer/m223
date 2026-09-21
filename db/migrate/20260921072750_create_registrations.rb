class CreateRegistrations < ActiveRecord::Migration[8.1]
  def change
    create_table :registrations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :concert, null: false, foreign_key: true

      t.timestamps
    end

    # Last line of defence against a double registration, even if validation is bypassed.
    add_index :registrations, [ :user_id, :concert_id ], unique: true
  end
end
