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

ActiveRecord::Schema.define(version: 20150610164319) do

  create_table "accounts", force: :cascade do |t|
    t.string   "zendesk_url",                   limit: 255
    t.string   "zendesk_access_token",          limit: 255
    t.string   "zendesk_user",                  limit: 255
    t.string   "ongair_token",                  limit: 255
    t.string   "ongair_phone_number",           limit: 255
    t.string   "ongair_url",                    limit: 255
    t.string   "zendesk_ticket_auto_responder", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "setup",                         limit: 1,   default: false
  end

  create_table "locations", force: :cascade do |t|
    t.string   "address",    limit: 255
    t.float    "latitude",   limit: 24
    t.float    "longitude",  limit: 24
    t.integer  "account_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "locations", ["account_id"], name: "index_locations_on_account_id", using: :btree

  create_table "tickets", force: :cascade do |t|
    t.string   "phone_number", limit: 255
    t.string   "ticket_id",    limit: 255
    t.string   "status",       limit: 255
    t.string   "source",       limit: 255
    t.integer  "account_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",      limit: 4
  end

  add_index "tickets", ["account_id"], name: "index_tickets_on_account_id", using: :btree
  add_index "tickets", ["user_id"], name: "index_tickets_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "name",              limit: 255
    t.string   "email",             limit: 255
    t.string   "messaging_service", limit: 255
    t.string   "phone_number",      limit: 255
    t.string   "zendesk_id",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_foreign_key "tickets", "users"
end
