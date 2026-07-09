# Represents a comment on an activity (e.g. a Post or another Comment).
# A Comment is a concrete objectable subtype of {ActivityObject}, carrying its own
# author, owner, and text (stored in the backing activity object's +description+).
#
# == Threading & Scoring
# Threading is managed in the +activities+ table via +parent_id+.
# Scores (upvotes/downvotes) are calculated from child activities with verb :like or :dislike.
class Comment < ApplicationRecord
  has_one :activity_object, as: :objectable, dependent: :destroy, autosave: true

  delegate :title, :title=, :description, :description=, :author, :author_id, :owner, :owner_id, :user_author, to: :activity_object, allow_nil: true

  # Alias text to description to match Post convention
  def text
    description
  end

  def text=(value)
    self.description = value
  end

  validates :text, presence: true

  before_create :generate_short_id

  # Find the post_activity that created this comment
  def activity
    activity_object&.activities&.find_by(verb: :post)
  end

  # Check if a user/actor can edit this comment (within 30 minutes, if not deleted/moderated)
  def editable_by?(actor)
    return false if actor.nil?
    return false if deleted? || moderated?
    activity_object.author_id == actor.id && created_at > 30.minutes.ago
  end

  # Check if an actor can delete this comment (author or wall owner)
  def destroyable_by?(actor)
    return false if actor.nil?
    activity_object.author_id == actor.id || activity_object.owner_id == actor.id
  end

  # Update the comment's score and Wilson confidence atomically
  def update_score!(comment_activity = nil)
    comment_activity ||= activity
    return unless comment_activity

    ups = comment_activity.children.where(verb: :like).count
    downs = comment_activity.children.where(verb: :dislike).count

    new_score = ups - downs
    new_confidence = Comment.wilson_confidence(ups, downs)

    update_columns(score: new_score, confidence: new_confidence)
  end

  # Wilson score confidence interval formula (from Lobsters/Reddit)
  # Computes lower bound of 80% confidence interval
  def self.wilson_confidence(ups, downs)
    return 0 if ups + downs == 0

    n = ups + downs
    z = 1.281551565545 # 80% confidence z-score
    phat = ups.to_f / n

    (phat + z*z/(2*n) - z * Math.sqrt((phat*(1-phat) + z*z/(4*n))/n)) / (1 + z*z/n)
  end

  private

  def generate_short_id
    loop do
      self.short_id = SecureRandom.alphanumeric(6).downcase
      break unless Comment.exists?(short_id: short_id)
    end
  end
end
