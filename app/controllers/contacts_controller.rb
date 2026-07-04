# Manages the current actor's {Contact Contacts} (its social connections). Creating a contact
# establishes a {Tie} through {Actor#connect_to}.
#
# @see ContactPolicy
# @see Actor#connect_to
class ContactsController < ApplicationController
  # Lists the current actor's established contacts (scoped via +ContactPolicy::Scope+) plus the
  # pending incoming requests from other profiles.
  def index
    authorize Contact
    @contacts = policy_scope(Contact)
                  .joins(:ties)
                  .where(sender_id: current_actor.id)
                  .includes(:receiver, :ties, :relations)
                  .distinct
    @pagy, @contacts = pagy(@contacts)

    @pending = Contact.pending
                      .where(receiver_id: current_actor.id)
                      .joins(:sender)
                      .merge(Actor.where(actorable_type: "Profile"))
                      .includes(:sender)
  end

  # Connects the current actor to another actor using the relation named by +params[:as]+
  # (defaults to +:friend+). Authorized via +ContactPolicy#create?+.
  #
  # @note Responds via Turbo Stream to update the contact UI without a page reload.
  def create
    other = Actor.find_by!(slug: params[:actor_id])
    authorize Contact.new(sender: current_actor, receiver: other)

    current_actor.connect_to(other, as: params[:as] || :friend)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to contacts_path, notice: "Contact added as #{params[:as] || :friend}." }
    end
  end

  # Removes a contact (authorized via +ContactPolicy#destroy?+).
  #
  # @note Responds via Turbo Stream to remove the contact from the list.
  def destroy
    @contact = Contact.find_by!(id: params[:id])
    authorize @contact
    @contact.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to contacts_path, notice: "Contact removed." }
    end
  end
end
