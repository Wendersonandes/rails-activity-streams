# == Schema Information
#
# Table name: activity_object_audiences
#
#  id                 :bigint           not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  activity_object_id :bigint           not null
#  relation_id        :bigint           not null
#
# Indexes
#
#  index_activity_object_audiences_on_relation_id  (relation_id)
#  index_ao_audiences_on_ao_id_and_relation_id     (activity_object_id,relation_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (activity_object_id => activity_objects.id) ON DELETE => cascade
#  fk_rails_...  (relation_id => relations.id) ON DELETE => cascade
#

# Join model sharing an {ActivityObject} with a {Relation}. Each {Relation} stands for the set
# of {Actor Actors} holding a {Tie} of that relation, so these records define the audience of
# an activity object independently of any {Activity} (see {ActivityObject.shared_with}).
#
# @see ActivityObject
# @see Relation
class ActivityObjectAudience < ApplicationRecord
  belongs_to :activity_object
  belongs_to :relation
end
