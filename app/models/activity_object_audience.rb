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
class ActivityObjectAudience < ApplicationRecord
  belongs_to :activity_object
  belongs_to :relation
end
