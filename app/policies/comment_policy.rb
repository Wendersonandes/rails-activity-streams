# Authorization policy for {Comment Comments}.
# Allows any signed-in actor to create, upvote, downvote, or flag comments.
# Only the author may update/edit a comment.
# The author or the wall owner (owner of the comment object) may delete/destroy it.
class CommentPolicy < ApplicationPolicy
  def create?
    user.present? && actor.present?
  end

  def reply?
    create?
  end

  def update?
    actor && record.author_id == actor.id
  end

  def destroy?
    author_or_owner?
  end

  def upvote?
    user.present? && actor.present?
  end

  def downvote?
    user.present? && actor.present?
  end

  def flag?
    user.present? && actor.present?
  end

  def unflag?
    user.present? && actor.present?
  end
end
