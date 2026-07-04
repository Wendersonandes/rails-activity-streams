# == Schema Information
#
# Table name: posts
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# A {Post} is the basic piece of user-generated content (a wall message). It is a concrete
# object subtype behind {ActivityObject}'s +delegated_type :objectable+, so a post can be the
# target of {Activity Activities} (posted, liked, commented) and shared with audiences.
#
# Its body is stored on the backing {ActivityObject} as +description+ and exposed here as
# {#text}.
#
# @see ActivityObject The object wrapper that carries authorship and audience.
class Post < ApplicationRecord
  has_one :activity_object, as: :objectable, dependent: :destroy, autosave: true

  delegate :title, :title=, :description, :description=, to: :activity_object, allow_nil: true

  # The post body. Alias of the backing activity object's +description+.
  #
  # @return [String, nil]
  def text
    description
  end

  # Sets the post body.
  #
  # @param value [String] the new body text.
  # @return [String]
  def text=(value)
    self.description = value
  end

  validates :text, presence: true

  MAXIMUM_LENGTH = 140
end
