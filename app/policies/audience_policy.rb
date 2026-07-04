# Authorization for {Audience Audiences}. Audiences are managed indirectly through
# {Activity} sharing rather than exposed as a resource, so listing is denied and the {Scope}
# is empty.
#
# @see Audience
class AudiencePolicy < ApplicationPolicy
  def index?
    false
  end

  class Scope < Scope
    def resolve
      scope.none
    end
  end
end
