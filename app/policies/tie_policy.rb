# Authorization for {Tie Ties}. Ties are an internal detail of the social graph (created and
# managed through {Contact Contacts} and services), so they are never exposed directly: every
# action is denied and the {Scope} is empty.
#
# @see Tie
# @see Contact
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
