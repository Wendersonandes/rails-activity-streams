class ActivityActionsController < ApplicationController
  before_action :set_ao

  def create
    action = @ao.received_actions.find_or_initialize_by(actor: current_actor)
    authorize action
    action.follow!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: activities_path }
    end
  end

  def destroy
    action = @ao.received_actions.find_by!(actor: current_actor)
    authorize action
    action.unfollow!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: activities_path }
    end
  end

  private

  def set_ao
    @activity = Activity.find(params[:activity_id])
    @ao = @activity.direct_object
    redirect_back fallback_location: activities_path, alert: "No object to act on." unless @ao
  end
end
