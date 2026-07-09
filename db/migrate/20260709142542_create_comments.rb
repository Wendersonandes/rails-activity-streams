class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.string :short_id, null: false
      t.integer :depth, null: false, default: 0
      t.integer :reply_count, null: false, default: 0
      t.integer :score, null: false, default: 1
      t.decimal :confidence, precision: 20, scale: 19, null: false, default: 0
      t.boolean :deleted, null: false, default: false
      t.boolean :moderated, null: false, default: false
      t.text :moderated_reason
      t.string :body_html
      t.datetime :last_edited_at

      t.timestamps
    end

    add_index :comments, :short_id, unique: true
  end
end
