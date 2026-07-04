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

# System {Relation} representing a one-way follow. It grants the +follow+ permission along
# with create/read access to activities, so a follower receives the followed actor's updates.
#
# @see Relation::Single
class Relation::Follow < Relation::Single
  PERMISSIONS = [
    [ "create", "activity" ],
    [ "read",   "activity" ],
    [ "follow", nil ]
  ].freeze
end
