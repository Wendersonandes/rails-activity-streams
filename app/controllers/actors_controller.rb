# Public-facing access to {Actor Actors}: a JSON search endpoint (used by autocomplete/mention
# pickers) and an actor's profile page with its activity feed.
#
# @see ActorPolicy
class ActorsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :show ]
  skip_after_action :verify_policy_scoped, only: [ :index ]

  # JSON actor search by name (authorized via +ActorPolicy#index?+). When
  # +params[:include_site_roles]+ is "true", each result is enriched with the actor's role on
  # the {Site} (resolved from the site actor's {Tie Ties}).
  def index
    authorize Actor
    @actors = Actor.name_search(params[:q])
                   .where.not(id: params[:exclude].presence&.split(","))
                   .includes(:actorable)
                   .limit(20)

    respond_to do |format|
      format.json do
        if params[:include_site_roles] == "true"
          site_actor = Site.instance.actor
          actor_ids = @actors.map(&:id)

          ties = Tie.joins(:contact, :relation)
                    .where(contacts: { sender_id: site_actor.id, receiver_id: actor_ids })
                    .select("contacts.receiver_id", "relations.name as relation_name")

          actor_roles = ties.each_with_object({}) { |tie, hash| hash[tie.receiver_id] = tie.relation_name.downcase }

          render json: @actors.map { |a|
            { id: a.id, name: a.name, slug: a.slug, type: a.actorable_type, role: actor_roles[a.id] || "none" }
          }
        else
          render json: @actors.map { |a|
            { id: a.id, name: a.name, slug: a.slug, type: a.actorable_type }
          }
        end
      end
    end
  end

  # An actor's profile page with its authored root activities, paginated and scoped through
  # +ActivityPolicy::Scope+. Authorized via +ActorPolicy#show?+.
  def show
    @actor = Actor.find_by!(slug: params[:id])
    authorize @actor
    @activities = policy_scope(Activity).where(author: @actor)
                                        .roots.recent
                                        .includes(:owner, { author: :avatar_attachment }, :user_author, :activity_objects, { parent: :author })
    @pagy, @activities = pagy(@activities)
  end
end
