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

ActiveRecord::Schema[7.1].define(version: 2024_12_07_170855) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "council_members", force: :cascade do |t|
    t.string "name"
    t.string "position"
    t.text "social_links"
    t.integer "municipality_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "election_cycle_id"
    t.date "next_election_date"
    t.integer "first_term_start_year"
    t.integer "terms_served", default: 1
    t.index ["election_cycle_id"], name: "index_council_members_on_election_cycle_id"
    t.index ["municipality_id"], name: "index_council_members_on_municipality_id"
  end

  create_table "development_projects", force: :cascade do |t|
    t.integer "municipality_id", null: false
    t.string "name"
    t.string "project_type"
    t.string "status"
    t.text "description"
    t.date "estimated_completion"
    t.decimal "estimated_cost"
    t.string "developer_name"
    t.string "project_url"
    t.json "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["municipality_id"], name: "index_development_projects_on_municipality_id"
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
    t.integer "cycle_years"
    t.string "name"
    t.index ["municipality_id"], name: "index_election_cycles_on_municipality_id"
  end

  create_table "municipal_resources", force: :cascade do |t|
    t.string "title"
    t.string "url"
    t.text "description"
    t.string "category"
    t.datetime "last_updated"
    t.integer "municipality_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["municipality_id"], name: "index_municipal_resources_on_municipality_id"
  end

  create_table "municipalities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "state"
    t.string "country"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "image_url"
    t.index ["name"], name: "index_municipalities_on_name"
  end

  create_table "news_articles", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "url"
    t.datetime "published_at"
    t.integer "municipality_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["municipality_id"], name: "index_news_articles_on_municipality_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "council_members", "election_cycles"
  add_foreign_key "council_members", "municipalities"
  add_foreign_key "development_projects", "municipalities"
  add_foreign_key "development_scores", "municipalities"
  add_foreign_key "election_cycles", "municipalities"
  add_foreign_key "municipal_resources", "municipalities"
  add_foreign_key "news_articles", "municipalities"
end
