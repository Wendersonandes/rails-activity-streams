class GroupCreation
  def initialize(creator_actor, group)
    @creator = creator_actor
    @group = group
  end

  def call
    ActiveRecord::Base.transaction do
      @group.save!

      activity_object = ActivityObject.create!(
        objectable: @group,
        title: @group.name,
        description: @group.description
      )

      @group.actor.update!(activity_object: activity_object)
      @group.actor.connect_to(@creator, as: "admin")

      @group
    end
  end
end
