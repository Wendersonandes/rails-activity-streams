# Authorization for {Activity Activities}. Any signed-in user may list and create activities;
# an activity is shown when it is public or {Activity#visible_to? visible} to the acting actor;
# only its author or owner may update or destroy it. The {Scope} narrows listings to the
# activities shared with the acting actor.
#
# @see Activity
class ActivityPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    record.public? || actor && record.visible_to?(actor)
  end

  def create?
    user.present?
  end

  def update?
    author_or_owner?
  end

  def destroy?
    author_or_owner?
  end

  class Scope < Scope
    # @return [ActiveRecord::Relation<Activity>] activities shared with the acting actor.
    def resolve
      scope.shared_with(actor)
    end
  end
end
