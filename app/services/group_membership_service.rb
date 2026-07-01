class GroupMembershipService
  def initialize(group_actor, member_actor)
    @group = group_actor
    @member = member_actor
  end

  def add(role: "member")
    @group.connect_to(@member, as: role)
  end

  def change_role(from:, to:)
    @group.disconnect_from(@member, from)
    @group.connect_to(@member, as: to)
  end

  def remove(role: nil)
    if role
      @group.disconnect_from(@member, role)
    else
      @group.ties_to(@member).destroy_all
    end
  end
end
