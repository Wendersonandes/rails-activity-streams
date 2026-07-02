class ProfileCreation
  def initialize(user, name: nil)
    @user = user
    @name = name || user.email.split("@").first
  end

  def call
    actor = nil

    ActiveRecord::Base.transaction do
      profile = Profile.create!(user: @user)
      activity_object = ActivityObject.create!(objectable: profile, title: @name)
      actor = Actor.create!(actorable: profile, name: @name, activity_object: activity_object)

      Site.instance.actor.connect_to(actor, as: "member")
    end

    actor
  end
end
