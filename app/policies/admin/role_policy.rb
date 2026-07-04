# Authorization for the admin *roles* area, where site administrators manage relations and
# permissions. Every action requires the acting actor to hold the +Admin+ role on the
# {Site}'s actor (see {Relation::LocalAdmin}).
#
# @see Site
# @see Relation::LocalAdmin
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

  # Does the acting actor hold the +Admin+ role on the site's actor?
  # @return [Boolean]
  def site_admin?
    return false unless actor
    Site.instance.actor.has_relation_with?(actor, "Admin")
  end
end
