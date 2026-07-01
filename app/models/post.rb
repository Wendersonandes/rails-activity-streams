# == Schema Information
#
# Table name: posts
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Post < ApplicationRecord
  has_one :activity_object, as: :objectable, dependent: :destroy, autosave: true

  delegate :title, :title=, :description, :description=, to: :activity_object, allow_nil: true

  def text
    description
  end

  def text=(value)
    self.description = value
  end

  validates :text, presence: true

  MAXIMUM_LENGTH = 140
end
