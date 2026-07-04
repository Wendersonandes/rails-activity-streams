# Authorization for {Permission Permissions}. Permissions are a fixed system catalog assigned
# to {Relation Relations}, not a user-facing resource, so listing is denied and the {Scope} is
# empty.
#
# @see Permission
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
