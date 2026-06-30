class ActorPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.present?
  end

  def update?
    actor == record
  end

  def destroy?
    actor == record
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
