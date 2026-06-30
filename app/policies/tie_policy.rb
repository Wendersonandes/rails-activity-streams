class TiePolicy < ApplicationPolicy
  def index?
    false
  end

  def show?
    false
  end

  class Scope < Scope
    def resolve
      scope.none
    end
  end
end
