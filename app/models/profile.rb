# == Schema Information
#
# Table name: profiles
#
#  id           :bigint           not null, primary key
#  address      :string
#  birthday     :date
#  city         :string
#  country      :string
#  experience   :text
#  fax          :string
#  im           :string
#  mobile       :string
#  organization :string
#  phone        :string
#  province     :string
#  skype        :string
#  website      :string
#  zipcode      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_profiles_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => restrict
#
class Profile < ApplicationRecord
  has_one :actor, as: :actorable, dependent: :destroy, autosave: true
  has_one :activity_object, as: :objectable, dependent: :destroy, autosave: true
  belongs_to :user

  delegate :name, :name=, :email, :email=, :slug, :description, :description=,
           :notification_settings, :activity_object_id,
           to: :actor, allow_nil: true

  accepts_nested_attributes_for :actor, update_only: true

  validates :user, presence: true
end
