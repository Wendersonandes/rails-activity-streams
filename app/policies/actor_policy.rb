# Authorization for {Actor Actors}. Actors are publicly listable and viewable; any signed-in
# user may create one, but only the acting actor may update or destroy itself.
#
# @see Actor
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
