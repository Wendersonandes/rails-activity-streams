# Authorization for {Audience Audiences}. Audiences are managed indirectly through
# {Activity} sharing rather than exposed as a resource, so listing is denied and the {Scope}
# is empty. Site admins may inspect audiences via the admin panel.
#
# @see Audience
class AudiencePolicy < ApplicationPolicy
  def index?
    site_admin?
  end

  private

  def site_admin?
    return false unless actor
    Site.instance.actor.has_relation_with?(actor, "Admin")
  end

  class Scope < Scope
    def resolve
      scope.none
    end
  end
end
