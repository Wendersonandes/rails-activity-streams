class AddSentContactsCountToActors < ActiveRecord::Migration[8.1]
  def change
    add_column :actors, :sent_contacts_count, :integer, default: 0, null: false

    up_only do
      Actor.reset_column_information
      Actor.find_each do |actor|
        Actor.reset_counters(actor.id, :sent_contacts)
      end
    end
  end
end

