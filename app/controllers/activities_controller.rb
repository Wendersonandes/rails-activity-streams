# Handles the activity stream: the home timeline, showing a single {Activity}, and publishing
# or removing activities. Creation delegates the heavy lifting (building the {Post}/
# {ActivityObject} and distributing to {Audience audiences}) to {ActivityCreation}.
#
# @see ActivityCreation
# @see ActivityPolicy
class ActivitiesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :show ]
  before_action :set_activity, only: [ :show, :destroy ]

  # The signed-in actor's home timeline, paginated and narrowed to what they may see.
  #
  # Authorized via +ActivityPolicy#index?+; the listing is scoped through
  # +ActivityPolicy::Scope+ before {Activity.home_timeline}.
  def index
    authorize Activity
    @pagy, @activities = pagy(
      policy_scope(Activity).home_timeline(current_actor)
    )
    if current_actor
      @activity = Activity.new(verb: :post, author: current_actor, owner: current_actor)
    end
  end

  def show
    authorize @activity
  end

  def new
    owner = params[:owner_id].present? ? Actor.find(params[:owner_id]) : current_actor
    @activity = Activity.new(verb: :post, author: current_actor, owner: owner)
    authorize @activity
  end

  # Publishes a new activity. The current actor is set as author and owner, and the current
  # user as +user_author+. The persistence of the post content and the audience distribution
  # are delegated to {ActivityCreation}.
  #
  # Authorized via +ActivityPolicy#create?+. On validation failure re-renders +new+ with 422.
  #
  # @note Responds via Turbo Stream by prepending the rendered activity to the +feed+ element,
  #   updating the stream in place without a full page reload.
  def create
    @activity = Activity.new(activity_params.except(:text, :relation_ids).merge(
      author: current_actor, user_author: current_user
    ))
    @activity.owner = current_actor unless @activity.owner_id.present?

    relation_ids = activity_params[:relation_ids]
    if relation_ids.blank? && @activity.owner != current_actor
      relation_ids = @activity.owner.activity_relation_ids
    end
    @activity.relation_ids_to_authorize = relation_ids

    authorize @activity

    @activity = ActivityCreation.new(
      @activity,
      text: activity_params[:text],
      relation_ids: relation_ids
    ).call

    respond_to do |format|
      format.turbo_stream do
        @new_activity = Activity.new(verb: :post, author: current_actor, owner: @activity.owner)
        render turbo_stream: [
          turbo_stream.prepend("feed", partial: "shared/activity", locals: { activity: @activity }),
          turbo_stream.replace("activity_form_container", partial: "activities/form", locals: { activity: @new_activity, clear_inputs: true })
        ]
      end
      format.html { redirect_to @activity, notice: "Post created." }
    end
  rescue ActiveRecord::RecordInvalid => e
    @activity = e.record.is_a?(Activity) ? e.record : @activity
    @activity.errors.add(:base, e.message) unless e.record.is_a?(Activity)
    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("activity_form_container", partial: "activities/form", locals: { activity: @activity }), status: :unprocessable_entity
      end
    end
  end

  # Removes the activity (authorized via +ActivityPolicy#destroy?+).
  #
  # @note Responds via Turbo Stream by removing the activity's element from the page.
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
    @activity = Activity.includes({ author: :avatar_attachment }, :user_author, :activity_objects, children: { author: :avatar_attachment }).find_by!(id: params[:id])
  end

  def activity_params
    params.require(:activity).permit(:verb, :owner_id, :parent_id, text: {}, relation_ids: [])
  end
end
