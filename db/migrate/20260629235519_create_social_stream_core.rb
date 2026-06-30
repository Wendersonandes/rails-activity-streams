class CreateSocialStreamCore < ActiveRecord::Migration[8.1]
  def change
    # ─── 1. activity_objects — DelegatedType base: objectable (Profile|Group|Post|Comment) ───
    create_table :activity_objects do |t|
      t.string :objectable_type, null: false
      t.bigint :objectable_id,   null: false
      t.string :title,          default: ""
      t.text   :description
      t.bigint :author_id
      t.bigint :owner_id
      t.bigint :user_author_id
      t.jsonb  :payload,        default: {}
      t.integer :like_count,     default: 0
      t.integer :follower_count, default: 0
      t.integer :visit_count,    default: 0
      t.integer :comment_count,  default: 0
      t.timestamps
    end
    add_index :activity_objects, [ :objectable_type, :objectable_id ], unique: true
    add_index :activity_objects, :author_id
    add_index :activity_objects, :owner_id
    add_index :activity_objects, :user_author_id

    # ─── 2. actors — DelegatedType base: actorable (Profile|Group) ───
    create_table :actors do |t|
      t.string :actorable_type, null: false
      t.bigint :actorable_id,   null: false
      t.string :name,           null: false
      t.string :slug,           null: false
      t.string :email
      t.text   :description
      t.bigint :activity_object_id
      t.jsonb  :notification_settings, default: {}
      t.timestamps
    end
    add_index :actors, :slug, unique: true
    add_index :actors, [ :actorable_type, :actorable_id ], unique: true
    add_index :actors, :activity_object_id
    add_foreign_key :actors, :activity_objects, on_delete: :nullify

    # ─── 3. profiles — Actor subtype for individual users ───
    create_table :profiles do |t|
      t.bigint :user_id, null: false
      t.date   :birthday
      t.string :phone, :mobile, :fax
      t.string :address, :city, :zipcode, :province, :country
      t.string :website, :skype, :im
      t.string :organization
      t.text   :experience
      t.timestamps
    end
    add_index :profiles, :user_id
    add_foreign_key :profiles, :users, on_delete: :restrict

    # ─── 4. groups — Actor subtype for groups/organizations ───
    create_table :groups do |t|
      t.timestamps
    end

    # ─── 5. permissions — action × object pairs (Rails enum, integer columns) ───
    create_table :permissions do |t|
      t.integer :action, null: false
      t.integer :object, null: false
      t.timestamps
    end
    add_index :permissions, [ :action, :object ], unique: true

    # ─── 6. relations — STI: Custom, Public, Follow, Owner, Reject, LocalAdmin ───
    create_table :relations do |t|
      t.string :type
      t.bigint :actor_id
      t.string :name, null: false
      t.bigint :parent_id
      t.string :sender_type
      t.string :receiver_type
      t.timestamps
    end
    add_index :relations, :actor_id
    add_index :relations, :parent_id
    add_foreign_key :relations, :actors, on_delete: :restrict
    add_foreign_key :relations, :relations, column: :parent_id, on_delete: :nullify

    # ─── 7. relation_permissions — join ───
    create_table :relation_permissions do |t|
      t.bigint :relation_id,   null: false
      t.bigint :permission_id, null: false
      t.timestamps
    end
    add_index :relation_permissions, [ :relation_id, :permission_id ], unique: true
    add_foreign_key :relation_permissions, :relations,   on_delete: :cascade
    add_foreign_key :relation_permissions, :permissions, on_delete: :cascade

    # ─── 8. activities — social feed items (verb is Rails enum, no lookup table) ───
    create_table :activities do |t|
      t.integer :verb,            null: false
      t.bigint :author_id,        null: false
      t.bigint :owner_id,         null: false
      t.bigint :user_author_id,   null: false
      t.bigint :parent_id
      t.timestamps
    end
    add_index :activities, :verb
    add_index :activities, :author_id
    add_index :activities, :owner_id
    add_index :activities, :user_author_id
    add_index :activities, :parent_id
    add_index :activities, :created_at
    add_foreign_key :activities, :actors, column: :author_id,      on_delete: :restrict
    add_foreign_key :activities, :actors, column: :owner_id,       on_delete: :restrict
    add_foreign_key :activities, :users,  column: :user_author_id, on_delete: :restrict
    add_foreign_key :activities, :activities, column: :parent_id,  on_delete: :nullify

    # ─── 9. activity_actions — explicit actions on objects (follow) ───
    create_table :activity_actions do |t|
      t.bigint :actor_id,            null: false
      t.bigint :activity_object_id,  null: false
      t.boolean :follow, default: false
      t.timestamps
    end
    add_index :activity_actions, [ :actor_id, :activity_object_id ], unique: true
    add_index :activity_actions, :activity_object_id
    add_foreign_key :activity_actions, :actors,           on_delete: :restrict
    add_foreign_key :activity_actions, :activity_objects, on_delete: :restrict

    # ─── 10. contacts — ordered pair of actors ───
    create_table :contacts do |t|
      t.bigint :sender_id,   null: false
      t.bigint :receiver_id, null: false
      t.bigint :inverse_id
      t.integer :ties_count, default: 0
      t.timestamps
    end
    add_index :contacts, [ :sender_id, :receiver_id ], unique: true
    add_index :contacts, :inverse_id
    add_foreign_key :contacts, :actors, column: :sender_id,   on_delete: :restrict
    add_foreign_key :contacts, :actors, column: :receiver_id, on_delete: :restrict
    add_foreign_key :contacts, :contacts, column: :inverse_id, on_delete: :nullify

    # ─── 11. ties — contact × relation link ───
    create_table :ties do |t|
      t.bigint :contact_id,  null: false
      t.bigint :relation_id, null: false
      t.timestamps
    end
    add_index :ties, [ :contact_id, :relation_id ], unique: true
    add_index :ties, :relation_id
    add_foreign_key :ties, :contacts,  on_delete: :restrict
    add_foreign_key :ties, :relations, on_delete: :restrict

    # ─── 12. audiences — activity visibility per relation ───
    create_table :audiences do |t|
      t.bigint :activity_id, null: false
      t.bigint :relation_id, null: false
      t.timestamps
    end
    add_index :audiences, [ :activity_id, :relation_id ], unique: true
    add_index :audiences, :relation_id
    add_foreign_key :audiences, :activities, on_delete: :cascade
    add_foreign_key :audiences, :relations,  on_delete: :cascade

    # ─── 13. activity_object_audiences — object visibility per relation ───
    create_table :activity_object_audiences do |t|
      t.bigint :activity_object_id, null: false
      t.bigint :relation_id,        null: false
      t.timestamps
    end
    add_index :activity_object_audiences, [ :activity_object_id, :relation_id ],
              unique: true, name: "index_ao_audiences_on_ao_id_and_relation_id"
    add_index :activity_object_audiences, :relation_id
    add_foreign_key :activity_object_audiences, :activity_objects, on_delete: :cascade
    add_foreign_key :activity_object_audiences, :relations,        on_delete: :cascade

    # ─── 14. activity_object_activities — join ───
    create_table :activity_object_activities do |t|
      t.bigint :activity_id,        null: false
      t.bigint :activity_object_id, null: false
      t.string :object_type,        default: "object"
      t.timestamps
    end
    add_index :activity_object_activities, :activity_id
    add_index :activity_object_activities, :activity_object_id
    add_foreign_key :activity_object_activities, :activities,       on_delete: :cascade
    add_foreign_key :activity_object_activities, :activity_objects, on_delete: :cascade

    # ─── Deferred FKs (dependent tables now exist) ───
    add_foreign_key :users, :actors, column: :current_profile_id, on_delete: :nullify
    add_foreign_key :activity_objects, :actors, column: :author_id,      on_delete: :restrict
    add_foreign_key :activity_objects, :actors, column: :owner_id,       on_delete: :restrict
    add_foreign_key :activity_objects, :users,  column: :user_author_id, on_delete: :restrict
  end
end
