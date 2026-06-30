class PermissionPolicy < ApplicationPolicy
  def index?
    false
  end

  class Scope < Scope
    def resolve
      scope.none
    end
  end
end
