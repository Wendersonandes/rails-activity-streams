# CRUD for {Group Groups}. Because a group participates in the graph through its {Actor},
# authorization operates on +@group.actor+ with an explicit +policy_class: GroupPolicy+, and
# creation is delegated to {GroupCreation} (which builds the activity object and the founder's
# admin tie).
#
# @see GroupCreation
# @see GroupPolicy
class GroupsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index, :show ]
  before_action :set_group, only: [ :show, :edit, :update, :destroy ]

  # Lists group actors, paginated. Scoped through +ActorPolicy::Scope+ and filtered to groups.
  def index
    authorize Actor
    @groups = policy_scope(Actor).where(actorable_type: "Group").includes(actorable: :actor)
    @pagy, @groups = pagy(@groups)
    @groups = @groups.to_a
  end

  def show
    authorize @group.actor, policy_class: GroupPolicy
    @activities = policy_scope(Activity).where(author: @group.actor)
                                        .roots.recent
                                        .includes({ author: :avatar_attachment }, :user_author, :activity_objects, { parent: :author })
    @pagy, @activities = pagy(@activities)

    @is_member = current_actor && @group.actor.member_roles_for(current_actor).any?
    if @is_member
      @admins     = @group.actor.contacts_for("admin").includes(:avatar_attachment).to_a
      @moderators = @group.actor.contacts_for("moderator").includes(:avatar_attachment).to_a
      @members    = @group.actor.contacts_for("member").includes(:avatar_attachment).to_a
    end
  end

  def new
    @group = Group.new
    @group.build_actor
    authorize @group.actor, policy_class: GroupPolicy
  end

  # Creates a group, delegating persistence and the founder's admin tie to {GroupCreation}.
  #
  # Authorized via +GroupPolicy#create?+ (on the built actor). On validation failure re-renders
  # +new+ with 422.
  def create
    @group = Group.new(group_params)
    authorize @group.actor, policy_class: GroupPolicy

    @group = GroupCreation.new(current_actor, @group).call
    redirect_to group_path(@group), notice: "Group created."
  rescue ActiveRecord::RecordInvalid => e
    @group = e.record
    render :new, status: :unprocessable_entity
  end

  def edit
    authorize @group.actor, policy_class: GroupPolicy
  end

  def update
    authorize @group.actor, policy_class: GroupPolicy
    if @group.update(group_params)
      redirect_to group_path(@group), notice: "Group updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @group.actor, policy_class: GroupPolicy
    @group.actor.destroy
    redirect_to groups_path, notice: "Group deleted."
  end

  private

  def set_group
    @group = Group.includes(:actor).find_by!(id: params[:id])
  end

  def group_params
    params.require(:group).permit(
      :privacy,
      actor_attributes: [ :id, :name, :description, :email, :avatar, :cover_image ]
    )
  end
end
