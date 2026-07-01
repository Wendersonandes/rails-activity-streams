class CleanupProfileColumns < ActiveRecord::Migration[8.1]
  def change
    remove_column :profiles, :skype, :string
    remove_column :profiles, :fax, :string
    remove_column :profiles, :province, :string
    remove_column :profiles, :experience, :text
    remove_column :profiles, :im, :string
    add_column :profiles, :state, :string
  end
end
