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

ActiveRecord::Schema[7.1].define(version: 2024_12_01_202542) do
  create_table "council_members", force: :cascade do |t|
    t.string "name"
    t.string "position"
    t.text "social_links"
    t.integer "municipality_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["municipality_id"], name: "index_council_members_on_municipality_id"
  end

  create_table "development_scores", force: :cascade do |t|
    t.integer "current_score"
    t.integer "municipality_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["municipality_id"], name: "index_development_scores_on_municipality_id"
  end

  create_table "election_cycles", force: :cascade do |t|
    t.date "next_election_date"
    t.integer "municipality_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["municipality_id"], name: "index_election_cycles_on_municipality_id"
  end

  create_table "municipalities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "state"
    t.string "country"
    t.index ["name"], name: "index_municipalities_on_name"
  end

  add_foreign_key "council_members", "municipalities"
  add_foreign_key "development_scores", "municipalities"
  add_foreign_key "election_cycles", "municipalities"
end
