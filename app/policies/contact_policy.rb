class ContactPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def create?
    user.present?
  end

  def destroy?
    actor && record.sender_id == actor.id
  end

  class Scope < Scope
    def resolve
      return scope.none unless actor
      scope.where(sender_id: actor.id)
    end
  end
end
