class ActivityPolicy < ApplicationPolicy
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
    def resolve
      scope.shared_with(actor)
    end
  end
end
