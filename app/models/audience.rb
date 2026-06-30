# == Schema Information
#
# Table name: audiences
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  activity_id :bigint           not null
#  relation_id :bigint           not null
#
# Indexes
#
#  index_audiences_on_activity_id_and_relation_id  (activity_id,relation_id) UNIQUE
#  index_audiences_on_relation_id                  (relation_id)
#
# Foreign Keys
#
#  fk_rails_...  (activity_id => activities.id) ON DELETE => cascade
#  fk_rails_...  (relation_id => relations.id) ON DELETE => cascade
#
class Audience < ApplicationRecord
  belongs_to :activity
  belongs_to :relation
end
