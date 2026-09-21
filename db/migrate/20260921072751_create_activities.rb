class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.references :concert, null: false, foreign_key: true
      t.string :action, null: false
      t.text :details

      t.timestamps
    end

    add_index :activities, :created_at
  end
end
