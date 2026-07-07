# Authorization for {Like Likes}. Any signed-in user may create a like;
# only its author or owner may destroy it.
#
# @see Like
class LikePolicy < ApplicationPolicy
  def create?
    return false unless user.present? && actor.present?
    return false if record.object.nil?

    if record.object.is_a?(Activity)
      record.object.visible_to?(actor)
    elsif record.object.is_a?(ActivityObject)
      record.object.visible_to?(actor)
    elsif record.object.respond_to?(:activity_object) && record.object.activity_object
      record.object.activity_object.visible_to?(actor)
    else
      true
    end
  end

  def destroy?
    author_or_owner?
  end
end
