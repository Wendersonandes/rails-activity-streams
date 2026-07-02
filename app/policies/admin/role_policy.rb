class Admin::RolePolicy < ApplicationPolicy
  def index?
    site_admin?
  end

  def create?
    site_admin?
  end

  def update?
    site_admin?
  end

  private

  def site_admin?
    return false unless actor
    Site.instance.actor.has_relation_with?(actor, "Admin")
  end
end
