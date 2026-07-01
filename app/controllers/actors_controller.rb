class ActorsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :show ]
  skip_after_action :verify_policy_scoped, only: [ :index ]

  def index
    authorize Actor
    @actors = Actor.name_search(params[:q])
                   .where.not(id: params[:exclude].presence&.split(","))
                   .includes(:actorable)
                   .limit(20)

    respond_to do |format|
      format.json do
        render json: @actors.map { |a|
          { id: a.id, name: a.name, slug: a.slug, type: a.actorable_type }
        }
      end
    end
  end

  def show
    @actor = Actor.find_by!(slug: params[:id])
    authorize @actor
    @activities = policy_scope(Activity).where(author: @actor)
                                        .roots.recent
                                        .includes(:author, :owner, :activity_objects)
    @pagy, @activities = pagy(@activities)
  end
end
