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

ActiveRecord::Schema.define(version: 2021_04_06_015744) do

  create_table "admin_actions", charset: "utf8", force: :cascade do |t|
    t.bigint "admin_user_id", null: false
    t.bigint "user_id"
    t.string "action", null: false
    t.string "change_from"
    t.string "change_to"
    t.text "long_action"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_admin_actions_on_admin_user_id"
    t.index ["user_id"], name: "index_admin_actions_on_user_id"
  end

  create_table "secrets", charset: "utf8", force: :cascade do |t|
    t.integer "version"
    t.text "secret"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "short_lived_data", charset: "utf8", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "data", null: false
    t.string "reason"
    t.datetime "death_time", null: false
    t.string "extra"
    t.integer "exclusive_use_count", default: 0
    t.integer "exclusive_use_count_max"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["data", "reason"], name: "index_short_lived_data_on_data_and_reason"
    t.index ["data"], name: "index_short_lived_data_on_data"
  end

  create_table "users", charset: "utf8", force: :cascade do |t|
    t.string "first_name", default: "", null: false
    t.string "last_name", default: "", null: false
    t.string "phone_number"
    t.timestamp "last_mfa_login"
    t.boolean "email_validated", default: false
    t.boolean "mfa_enabled", default: false, null: false
    t.boolean "active", default: true, null: false
    t.string "admin"
    t.string "last_known_timezone"
    t.timestamp "last_known_timezone_update"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_users_on_active"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
