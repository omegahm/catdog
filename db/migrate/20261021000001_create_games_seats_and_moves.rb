class CreateGamesSeatsAndMoves < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.string :public_id, null: false, index: { unique: true }
      t.integer :rules_version, null: false, default: 1
      t.json :tile_sets, null: false, default: [ "base" ]
      t.string :status, null: false, default: "lobby"
      t.integer :first_seat
      t.integer :turn_seat
      t.integer :winner_seat
      t.integer :state_seq, null: false, default: 0
      t.json :state
      t.integer :rematch_offered_by
      t.references :rematch_game, foreign_key: { to_table: :games }
      t.timestamps
    end

    create_table :seats do |t|
      t.references :game, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :token_digest, null: false
      t.integer :user_id
      t.timestamps
    end
    add_index :seats, [ :game_id, :position ], unique: true
    add_index :seats, [ :game_id, :token_digest ], unique: true

    create_table :moves do |t|
      t.references :game, null: false, foreign_key: true, index: false
      t.integer :seq, null: false
      t.integer :seat_position, null: false
      t.string :kind, null: false
      t.json :data, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :moves, [ :game_id, :seq ], unique: true
  end
end
