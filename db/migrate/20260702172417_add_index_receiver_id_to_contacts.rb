class AddIndexReceiverIdToContacts < ActiveRecord::Migration[8.1]
  def change
    add_index :contacts, :receiver_id
  end
end
