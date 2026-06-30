class MakeObjectNullableOnPermissions < ActiveRecord::Migration[8.1]
  def change
    change_column_null :permissions, :object, true
  end
end
