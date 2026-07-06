# Background job to publish contact {Activity} and its associated {Audience} records.
# This keeps the HTTP connection response thin and fast, deferring side effects.
#
# @see Tie#enqueue_contact_activity_job
# @see Activity
class CreateContactActivityJob < ApplicationJob
  queue_as :default

  # Performs the asynchronous creation of follow or make_friend activities.
  #
  # @param tie_id [Integer] the ID of the Tie that was created.
  def perform(tie_id)
    tie = Tie.find_by(id: tie_id)
    return unless tie

    contact = tie.contact
    return if contact.reload.ties_count != 1

    Rails.logger.info "[CreateContactActivityJob] Creating activity for tie ##{tie_id}"

    sender_actor = contact.sender
    receiver_actor = contact.receiver

    is_group_connection = sender_actor.actorable_type == "Group" ||
                          receiver_actor.actorable_type == "Group"

    verb = if is_group_connection
      :join
    elsif contact.replied?
      :make_friend
    else
      :follow
    end

    Activity.transaction do
      activity = Activity.create!(
        verb: verb,
        author: sender_actor,
        user_author: sender_actor.subject.is_a?(Profile) ? sender_actor.subject.user : nil,
        owner: receiver_actor
      )

      receiver_actor.activity_relation_ids.each do |rid|
        activity.audiences.create!(relation_id: rid)
      end

      activity
    end

    Rails.logger.info "[CreateContactActivityJob] Activity #{verb} created for tie ##{tie_id}"
  end
end
