# Service object managing a member's role within a {Group}. Membership is expressed as
# {Tie Ties} from the group's {Actor} to the member's actor, using role relations (e.g.
# "member", "admin"). Each operation reshapes those ties.
#
# @see Group
# @see Actor#connect_to
# @see Actor#disconnect_from
class GroupMembershipService
  # @param group_actor [Actor] the group's actor.
  # @param member_actor [Actor] the member's actor.
  def initialize(group_actor, member_actor)
    @group = group_actor
    @member = member_actor
  end

  # Adds the member with the given role, replacing any existing ties first.
  #
  # @param role [String] the role relation name.
  # @return [Tie] the resulting membership tie.
  def add(role: "member")
    @group.ties_to(@member).destroy_all
    @group.connect_to(@member, as: role)
  end

  # Changes the member's role from one relation to another.
  #
  # @param from [String] the current role relation name.
  # @param to [String] the new role relation name.
  # @return [Tie] the resulting membership tie.
  def change_role(from:, to:)
    @group.disconnect_from(@member, from)
    @group.connect_to(@member, as: to)
  end

  # Removes the member. When +role+ is given, only that role tie is removed; otherwise all of
  # the member's ties to the group are destroyed.
  #
  # @param role [String, nil] the role relation name to remove, or +nil+ for all.
  # @return [void]
  def remove(role: nil)
    if role
      @group.disconnect_from(@member, role)
    else
      @group.ties_to(@member).destroy_all
    end
  end
end
