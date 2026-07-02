class ContactsController < ApplicationController
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

  def create
    other = Actor.find_by!(slug: params[:actor_id])
    authorize Contact.new(sender: current_actor, receiver: other)

    current_actor.connect_to(other, as: params[:as] || :friend)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to contacts_path, notice: "Contact added as #{params[:as] || :friend}." }
    end
  end

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
