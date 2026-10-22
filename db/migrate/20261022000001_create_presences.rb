class CreatePresences < ActiveRecord::Migration[8.1]
  def change
    create_table :presences do |t|
      t.references :seat, null: false, foreign_key: true
      t.string :connection_id, null: false, index: { unique: true }
      t.datetime :last_seen_at, null: false
    end
  end
end
