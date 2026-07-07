# Authorization for {ActivityAction ActivityActions} (e.g. follows). Any signed-in user may
# create one; only the actor that owns the action may destroy it. The {Scope} limits listings
# to the acting actor's own actions.
#
# @see ActivityAction
class ActivityActionPolicy < ApplicationPolicy
  def create?
    return false unless user.present? && actor.present?
    return false if record.activity_object.nil?

    record.activity_object.visible_to?(actor)
  end

  def destroy?
    actor && record.actor_id == actor.id
  end

  class Scope < Scope
    # @return [ActiveRecord::Relation<ActivityAction>] the acting actor's own actions.
    def resolve
      return scope.none unless actor
      scope.where(actor_id: actor.id)
    end
  end
end
