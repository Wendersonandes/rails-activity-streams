# Authorization for {User Users} (the authentication identity). A user may only view and
# update itself, and the {Scope} resolves to just that user.
#
# @see User
class UserPolicy < ApplicationPolicy
  def show?
    user == record
  end

  def update?
    user == record
  end

  class Scope < Scope
    # @return [ActiveRecord::Relation<User>] only the authenticated user.
    def resolve
      scope.where(id: user.id)
    end
  end
end
