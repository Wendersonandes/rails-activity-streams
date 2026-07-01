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

ActiveRecord::Schema[8.1].define(version: 2026_07_01_132128) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activities", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.datetime "created_at", null: false
    t.bigint "owner_id", null: false
    t.bigint "parent_id"
    t.datetime "updated_at", null: false
    t.bigint "user_author_id"
    t.integer "verb", null: false
    t.index ["author_id"], name: "index_activities_on_author_id"
    t.index ["created_at"], name: "index_activities_on_created_at"
    t.index ["owner_id"], name: "index_activities_on_owner_id"
    t.index ["parent_id"], name: "index_activities_on_parent_id"
    t.index ["user_author_id"], name: "index_activities_on_user_author_id"
    t.index ["verb"], name: "index_activities_on_verb"
  end

  create_table "activity_actions", force: :cascade do |t|
    t.bigint "activity_object_id", null: false
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.boolean "follow", default: false
    t.datetime "updated_at", null: false
    t.index ["activity_object_id"], name: "index_activity_actions_on_activity_object_id"
    t.index ["actor_id", "activity_object_id"], name: "index_activity_actions_on_actor_id_and_activity_object_id", unique: true
  end

  create_table "activity_object_activities", force: :cascade do |t|
    t.bigint "activity_id", null: false
    t.bigint "activity_object_id", null: false
    t.datetime "created_at", null: false
    t.string "object_type", default: "object"
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_activity_object_activities_on_activity_id"
    t.index ["activity_object_id"], name: "index_activity_object_activities_on_activity_object_id"
  end

  create_table "activity_object_audiences", force: :cascade do |t|
    t.bigint "activity_object_id", null: false
    t.datetime "created_at", null: false
    t.bigint "relation_id", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_object_id", "relation_id"], name: "index_ao_audiences_on_ao_id_and_relation_id", unique: true
    t.index ["relation_id"], name: "index_activity_object_audiences_on_relation_id"
  end

  create_table "activity_objects", force: :cascade do |t|
    t.bigint "author_id"
    t.integer "comment_count", default: 0
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "follower_count", default: 0
    t.integer "like_count", default: 0
    t.bigint "objectable_id", null: false
    t.string "objectable_type", null: false
    t.bigint "owner_id"
    t.jsonb "payload", default: {}
    t.string "title", default: ""
    t.datetime "updated_at", null: false
    t.bigint "user_author_id"
    t.integer "visit_count", default: 0
    t.index ["author_id"], name: "index_activity_objects_on_author_id"
    t.index ["objectable_type", "objectable_id"], name: "index_activity_objects_on_objectable_type_and_objectable_id", unique: true
    t.index ["owner_id"], name: "index_activity_objects_on_owner_id"
    t.index ["user_author_id"], name: "index_activity_objects_on_user_author_id"
  end

  create_table "actors", force: :cascade do |t|
    t.bigint "activity_object_id"
    t.bigint "actorable_id", null: false
    t.string "actorable_type", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "email"
    t.string "name", null: false
    t.jsonb "notification_settings", default: {}
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_object_id"], name: "index_actors_on_activity_object_id"
    t.index ["actorable_type", "actorable_id"], name: "index_actors_on_actorable_type_and_actorable_id", unique: true
    t.index ["slug"], name: "index_actors_on_slug", unique: true
  end

  create_table "audiences", force: :cascade do |t|
    t.bigint "activity_id", null: false
    t.datetime "created_at", null: false
    t.bigint "relation_id", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id", "relation_id"], name: "index_audiences_on_activity_id_and_relation_id", unique: true
    t.index ["relation_id"], name: "index_audiences_on_relation_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "inverse_id"
    t.bigint "receiver_id", null: false
    t.bigint "sender_id", null: false
    t.integer "ties_count", default: 0
    t.datetime "updated_at", null: false
    t.index ["inverse_id"], name: "index_contacts_on_inverse_id"
    t.index ["sender_id", "receiver_id"], name: "index_contacts_on_sender_id_and_receiver_id", unique: true
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.datetime "created_at"
    t.string "scope"
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "permissions", force: :cascade do |t|
    t.integer "action", null: false
    t.datetime "created_at", null: false
    t.integer "object"
    t.datetime "updated_at", null: false
    t.index ["action", "object"], name: "index_permissions_on_action_and_object", unique: true
  end

  create_table "posts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "profiles", force: :cascade do |t|
    t.string "address"
    t.date "birthday"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "mobile"
    t.string "organization"
    t.string "phone"
    t.string "state"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "website"
    t.string "zipcode"
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "relation_permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "permission_id", null: false
    t.bigint "relation_id", null: false
    t.datetime "updated_at", null: false
    t.index ["relation_id", "permission_id"], name: "index_relation_permissions_on_relation_id_and_permission_id", unique: true
  end

  create_table "relations", force: :cascade do |t|
    t.bigint "actor_id"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "parent_id"
    t.string "receiver_type"
    t.string "sender_type"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_relations_on_actor_id"
    t.index ["parent_id"], name: "index_relations_on_parent_id"
  end

  create_table "ties", force: :cascade do |t|
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.bigint "relation_id", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id", "relation_id"], name: "index_ties_on_contact_id_and_relation_id", unique: true
    t.index ["relation_id"], name: "index_ties_on_relation_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "current_profile_id"
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["current_profile_id"], name: "index_users_on_current_profile_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "activities", "activities", column: "parent_id", on_delete: :nullify
  add_foreign_key "activities", "actors", column: "author_id", on_delete: :restrict
  add_foreign_key "activities", "actors", column: "owner_id", on_delete: :restrict
  add_foreign_key "activities", "users", column: "user_author_id", on_delete: :restrict
  add_foreign_key "activity_actions", "activity_objects", on_delete: :restrict
  add_foreign_key "activity_actions", "actors", on_delete: :restrict
  add_foreign_key "activity_object_activities", "activities", on_delete: :cascade
  add_foreign_key "activity_object_activities", "activity_objects", on_delete: :cascade
  add_foreign_key "activity_object_audiences", "activity_objects", on_delete: :cascade
  add_foreign_key "activity_object_audiences", "relations", on_delete: :cascade
  add_foreign_key "activity_objects", "actors", column: "author_id", on_delete: :restrict
  add_foreign_key "activity_objects", "actors", column: "owner_id", on_delete: :restrict
  add_foreign_key "activity_objects", "users", column: "user_author_id", on_delete: :restrict
  add_foreign_key "actors", "activity_objects", on_delete: :nullify
  add_foreign_key "audiences", "activities", on_delete: :cascade
  add_foreign_key "audiences", "relations", on_delete: :cascade
  add_foreign_key "contacts", "actors", column: "receiver_id", on_delete: :restrict
  add_foreign_key "contacts", "actors", column: "sender_id", on_delete: :restrict
  add_foreign_key "contacts", "contacts", column: "inverse_id", on_delete: :nullify
  add_foreign_key "profiles", "users", on_delete: :restrict
  add_foreign_key "relation_permissions", "permissions", on_delete: :cascade
  add_foreign_key "relation_permissions", "relations", on_delete: :cascade
  add_foreign_key "relations", "actors", on_delete: :restrict
  add_foreign_key "relations", "relations", column: "parent_id", on_delete: :nullify
  add_foreign_key "ties", "contacts", on_delete: :restrict
  add_foreign_key "ties", "relations", on_delete: :restrict
  add_foreign_key "users", "actors", column: "current_profile_id", on_delete: :nullify
end
