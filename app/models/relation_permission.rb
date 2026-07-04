# == Schema Information
#
# Table name: relation_permissions
#
#  id            :bigint           not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  permission_id :bigint           not null
#  relation_id   :bigint           not null
#
# Indexes
#
#  index_relation_permissions_on_relation_id_and_permission_id  (relation_id,permission_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (permission_id => permissions.id) ON DELETE => cascade
#  fk_rails_...  (relation_id => relations.id) ON DELETE => cascade
#

# Join model between a {Relation} and a {Permission}. Assigning a {Permission} to a
# {Relation} is what lets that relation grant the permission to the receivers of its
# {Tie Ties}.
#
# @see Relation
# @see Permission
class RelationPermission < ApplicationRecord
  belongs_to :relation
  belongs_to :permission
end
