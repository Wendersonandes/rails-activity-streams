class GroupPolicy < ApplicationPolicy
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
    admin?
  end

  def destroy?
    admin?
  end

  def manage_members?
    admin?
  end

  def add_member?
    admin?
  end

  def remove_member?
    admin?
  end

  def change_role?
    admin?
  end

  def leave?
    member? || moderator? || admin?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end

  private

  def admin?
    return false unless actor
    record.has_relation_with?(actor, "Admin")
  end

  def moderator?
    return false unless actor
    record.has_relation_with?(actor, "Moderator")
  end

  def member?
    return false unless actor
    record.has_relation_with?(actor, "Member")
  end
end
