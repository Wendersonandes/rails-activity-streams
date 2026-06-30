# == Schema Information
#
# Table name: permissions
#
#  id         :bigint           not null, primary key
#  action     :integer          not null
#  object     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_permissions_on_action_and_object  (action,object) UNIQUE
#
class Permission < ApplicationRecord
  enum :action, { create: 0, read: 1, update: 2, destroy: 3, follow: 4, represent: 5 }, prefix: :action
  enum :object, { activity: 0, tie: 1, post: 2, comment: 3 }, prefix: :object

  has_many :relation_permissions, dependent: :destroy
  has_many :relations, through: :relation_permissions

  validates :action, presence: true

  scope :follow, -> { where(action: :follow) }
  scope :represent, -> { where(action: :represent) }

  class << self
    def instances(ary)
      ary.map { |action, object| find_or_create_by(action: action, object: object) }
    end

    def available(subject)
      subject_type = subject.class.to_s.underscore
      SocialStream.available_permissions[subject_type] ||
        SocialStream.available_permissions[subject.class.base_class.to_s.underscore] ||
        raise("Configure SocialStream.available_permissions[:#{subject_type}]")
    end
  end
end
