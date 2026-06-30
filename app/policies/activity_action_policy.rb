class ActivityActionPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def destroy?
    actor && record.actor_id == actor.id
  end

  class Scope < Scope
    def resolve
      return scope.none unless actor
      scope.where(actor_id: actor.id)
    end
  end
end
