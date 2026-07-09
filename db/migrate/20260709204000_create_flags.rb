class CreateFlags < ActiveRecord::Migration[8.1]
  def change
    create_table :flags do |t|
      t.string :reason, null: false
      t.text :note

      t.timestamps
    end
  end
end
