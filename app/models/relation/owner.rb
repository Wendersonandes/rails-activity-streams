# == Schema Information
#
# Table name: relations
#
#  id            :bigint           not null, primary key
#  name          :string           not null
#  receiver_type :string
#  sender_type   :string
#  type          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  actor_id      :bigint
#  parent_id     :bigint
#
# Indexes
#
#  index_relations_on_actor_id   (actor_id)
#  index_relations_on_parent_id  (parent_id)
#
# Foreign Keys
#
#  fk_rails_...  (actor_id => actors.id) ON DELETE => restrict
#  fk_rails_...  (parent_id => relations.id) ON DELETE => nullify
#

# System {Relation} granting a {Group}'s owner full permissions over it. Its permissions come
# from +SocialStream.available_permissions["group"]+. Owner ties do not publish an {Activity}.
#
# @see Relation::Single
class Relation::Owner < Relation::Single
  PERMISSIONS = (SocialStream.available_permissions["group"] || []).freeze

  class << self
    # Owner ties never publish a contact {Activity}.
    #
    # @return [Boolean] always false.
    def create_activity?
      false
    end
  end
end
