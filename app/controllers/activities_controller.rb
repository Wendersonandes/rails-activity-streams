class ActivitiesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :show ]
  before_action :set_activity, only: [ :show, :destroy ]

  def index
    authorize Activity
    @pagy, @activities = pagy(
      policy_scope(Activity).home_timeline(current_actor)
    )
  end

  def show
    authorize @activity
  end

  def new
    @activity = Activity.new(verb: :post, author: current_actor, owner: current_actor)
    authorize @activity
  end

  def create
    @activity = Activity.new(activity_params.except(:text, :relation_ids).merge(
      author: current_actor, user_author: current_user, owner: current_actor
    ))
    authorize @activity

    @activity = ActivityCreation.new(
      @activity,
      text: activity_params[:text],
      relation_ids: activity_params[:relation_ids]
    ).call

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.prepend("feed", partial: "shared/activity", locals: { activity: @activity }) }
      format.html { redirect_to @activity, notice: "Post created." }
    end
  rescue ActiveRecord::RecordInvalid => e
    @activity = e.record.is_a?(Activity) ? e.record : @activity
    @activity.errors.add(:base, e.message) unless e.record.is_a?(Activity)
    render :new, status: :unprocessable_entity
  end

  def destroy
    authorize @activity
    @activity.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@activity) }
      format.html { redirect_to activities_path, notice: "Activity deleted." }
    end
  end

  private

  def set_activity
    @activity = Activity.includes(:author, :user_author, :activity_objects, children: :author).find_by!(id: params[:id])
  end

  def activity_params
    params.require(:activity).permit(:verb, :owner_id, :parent_id, text: {}, relation_ids: [])
  end
end
