class AddPrivacyToGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :groups, :privacy, :integer, default: 0, null: false
  end
end
