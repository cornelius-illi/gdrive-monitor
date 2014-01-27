# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140127093721) do

  create_table "changes", force: true do |t|
    t.string   "change_id"
    t.integer  "resource_id"
    t.string   "etag"
    t.boolean  "deleted"
    t.datetime "modification_date"
    t.string   "last_modifying_username"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "owner_type"
    t.integer  "owner_id"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

  create_table "monitored_periods", force: true do |t|
    t.string   "name"
    t.datetime "start"
    t.datetime "end"
    t.integer  "user_id"
  end

  create_table "monitored_periods_monitored_resources", force: true do |t|
    t.integer "monitored_period_id"
    t.integer "monitored_resource_id"
  end

  create_table "monitored_resources", force: true do |t|
    t.string   "gid"
    t.integer  "largest_change_id"
    t.datetime "shared_with_me_date"
    t.datetime "lowest_index_date"
    t.datetime "structure_indexed_at"
    t.datetime "changehistory_indexed_at"
    t.datetime "created_date"
    t.datetime "modified_date"
    t.string   "title"
    t.string   "etag"
    t.string   "owner_names"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permission_groups", force: true do |t|
    t.string  "name"
    t.integer "monitored_resource_id"
  end

  create_table "permission_groups_permissions", force: true do |t|
    t.integer "permission_group_id"
    t.integer "permission_id"
  end

  create_table "permissions", force: true do |t|
    t.string  "gid"
    t.string  "name"
    t.string  "domain"
    t.string  "role"
    t.string  "perm_type"
    t.string  "email_address"
    t.integer "monitored_resource_id"
    t.integer "permission_group_id"
  end

  create_table "resources", force: true do |t|
    t.string   "gid"
    t.string   "kind"
    t.string   "etag"
    t.string   "alternate_link"
    t.string   "title"
    t.string   "mime_type"
    t.string   "file_extension"
    t.string   "file_size"
    t.string   "owner_names"
    t.string   "last_modifying_username"
    t.datetime "created_date"
    t.datetime "modified_date"
    t.boolean  "shared"
    t.boolean  "trashed"
    t.boolean  "viewed"
    t.integer  "monitored_resource_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "uid"
    t.string   "provider"
    t.string   "token"
    t.integer  "expires_at"
    t.string   "refresh_token"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true

end
