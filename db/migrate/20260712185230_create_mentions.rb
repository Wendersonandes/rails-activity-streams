class CreateMentions < ActiveRecord::Migration[8.1]
  def change
    create_table :mentions do |t|
      t.references :activity_object, null: false, foreign_key: { on_delete: :cascade }
      t.references :actor, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :mentions, [:activity_object_id, :actor_id], unique: true
  end
end
