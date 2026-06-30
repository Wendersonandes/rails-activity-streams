class ActorsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :show ]

  def show
    @actor = Actor.find_by!(slug: params[:id])
    authorize @actor
    @activities = policy_scope(Activity).where(author: @actor)
                                        .roots.recent
                                        .includes(:author, :owner, :activity_objects)
    @pagy, @activities = pagy(@activities)
  end
end
