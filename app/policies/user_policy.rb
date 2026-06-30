class UserPolicy < ApplicationPolicy
  def show?
    user == record
  end

  def update?
    user == record
  end

  class Scope < Scope
    def resolve
      scope.where(id: user.id)
    end
  end
end
