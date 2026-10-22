# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_22_000003) do
  create_table "games", force: :cascade do |t|
    t.string "public_id", null: false
    t.integer "rules_version", default: 2, null: false
    t.json "tile_sets", default: ["base"], null: false
    t.string "status", default: "lobby", null: false
    t.integer "first_seat"
    t.integer "turn_seat"
    t.integer "winner_seat"
    t.integer "state_seq", default: 0, null: false
    t.json "state"
    t.integer "rematch_offered_by"
    t.integer "rematch_game_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "hot_seat", default: false, null: false
    t.index ["public_id"], name: "index_games_on_public_id", unique: true
    t.index ["rematch_game_id"], name: "index_games_on_rematch_game_id"
  end

  create_table "moves", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "seq", null: false
    t.integer "seat_position", null: false
    t.string "kind", null: false
    t.json "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["game_id", "seq"], name: "index_moves_on_game_id_and_seq", unique: true
  end

  create_table "presences", force: :cascade do |t|
    t.integer "seat_id", null: false
    t.string "connection_id", null: false
    t.datetime "last_seen_at", null: false
    t.index ["connection_id"], name: "index_presences_on_connection_id", unique: true
    t.index ["seat_id"], name: "index_presences_on_seat_id"
  end

  create_table "seats", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "position", null: false
    t.string "token_digest", null: false
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "position"], name: "index_seats_on_game_id_and_position", unique: true
    t.index ["game_id", "token_digest"], name: "index_seats_on_game_id_and_token_digest", unique: true
    t.index ["game_id"], name: "index_seats_on_game_id"
  end

  add_foreign_key "games", "games", column: "rematch_game_id"
  add_foreign_key "moves", "games"
  add_foreign_key "presences", "seats"
  add_foreign_key "seats", "games"
end
