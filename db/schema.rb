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

ActiveRecord::Schema[8.1].define(version: 2026_10_21_000001) do
  create_table "games", force: :cascade do |t|
    t.integer "rules_version", default: 1, null: false
    t.json "tile_sets", default: ["base"], null: false
    t.string "status", default: "lobby", null: false
    t.integer "first_seat"
    t.integer "turn_seat"
    t.integer "winner_seat"
    t.integer "state_seq", default: 0, null: false
    t.json "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "seats", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "position", null: false
    t.string "token_digest", null: false
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "position"], name: "index_seats_on_game_id_and_position", unique: true
    t.index ["game_id"], name: "index_seats_on_game_id"
    t.index ["token_digest"], name: "index_seats_on_token_digest", unique: true
  end

  add_foreign_key "moves", "games"
  add_foreign_key "seats", "games"
end
