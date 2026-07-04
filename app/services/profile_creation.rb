# Service object that provisions a {Profile} for a {User}: it creates the profile, its backing
# {ActivityObject} and the {Actor} that represents it in the social graph, then connects that
# actor to the {Site} through the +member+ relation. Runs in a single transaction.
#
# Invoked from {User}'s +after_create+ callback to set up the user's initial profile.
#
# @see Profile
# @see Actor
class ProfileCreation
  # @param user [User] the owner of the new profile.
  # @param name [String, nil] the profile/actor name; defaults to the local part of the user's email.
  def initialize(user, name: nil)
    @user = user
    @name = name || user.email.split("@").first
  end

  # Creates the profile, activity object and actor, and joins the site.
  #
  # @return [Actor] the actor backing the new profile.
  # @raise [ActiveRecord::RecordInvalid] if any record fails validation (rolls back the transaction).
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
