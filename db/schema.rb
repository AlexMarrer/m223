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

ActiveRecord::Schema[8.1].define(version: 2026_09_21_072751) do
  create_table "activities", force: :cascade do |t|
    t.string "action", null: false
    t.integer "actor_id", null: false
    t.integer "concert_id", null: false
    t.datetime "created_at", null: false
    t.text "details"
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_activities_on_actor_id"
    t.index ["concert_id"], name: "index_activities_on_concert_id"
    t.index ["created_at"], name: "index_activities_on_created_at"
  end

  create_table "concerts", force: :cascade do |t|
    t.integer "capacity", null: false
    t.datetime "created_at", null: false
    t.integer "creator_id", null: false
    t.text "description"
    t.datetime "ends_at", null: false
    t.integer "lock_version", default: 0, null: false
    t.string "playlist_url"
    t.text "setlist"
    t.datetime "starts_at", null: false
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_concerts_on_creator_id"
    t.index ["status", "starts_at"], name: "index_concerts_on_status_and_starts_at"
    t.check_constraint "capacity > 0", name: "concerts_capacity_positive"
    t.check_constraint "ends_at > starts_at", name: "concerts_end_after_start"
    t.check_constraint "status IN ('draft', 'published', 'cancelled')", name: "concerts_status_valid"
  end

  create_table "registrations", force: :cascade do |t|
    t.integer "concert_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["concert_id"], name: "index_registrations_on_concert_id"
    t.index ["user_id", "concert_id"], name: "index_registrations_on_user_id_and_concert_id", unique: true
    t.index ["user_id"], name: "index_registrations_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "role", default: "user", null: false
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.check_constraint "role IN ('user', 'organizer', 'admin')", name: "users_role_valid"
  end

  add_foreign_key "activities", "concerts"
  add_foreign_key "activities", "users", column: "actor_id"
  add_foreign_key "concerts", "users", column: "creator_id"
  add_foreign_key "registrations", "concerts"
  add_foreign_key "registrations", "users"
  add_foreign_key "sessions", "users"
end
