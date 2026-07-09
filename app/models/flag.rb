# Represents a moderation flag on content.
# It is a concrete objectable subtype of {ActivityObject}, carrying its own
# author (the flagger), owner (the content author), reason, and note.
class Flag < ApplicationRecord
  has_one :activity_object, as: :objectable, dependent: :destroy, autosave: true
  delegate :author, :owner, :user_author, to: :activity_object, allow_nil: true

  validates :reason, presence: true, inclusion: { in: %w[spam harassment offtopic inappropriate] }
end
