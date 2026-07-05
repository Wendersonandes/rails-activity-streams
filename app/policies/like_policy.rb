# Authorization for {Like Likes}. Any signed-in user may create a like;
# only its author or owner may destroy it.
#
# @see Like
class LikePolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def destroy?
    author_or_owner?
  end
end
