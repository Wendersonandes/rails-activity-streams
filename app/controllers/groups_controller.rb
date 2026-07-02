class GroupsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index, :show ]
  before_action :set_group, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize Actor
    @groups = policy_scope(Actor).where(actorable_type: "Group").includes(actorable: :actor)
    @pagy, @groups = pagy(@groups)
  end

  def show
    authorize @group.actor, policy_class: GroupPolicy
    @activities = policy_scope(Activity).where(author: @group.actor)
                                        .roots.recent
                                        .includes(:author, :user_author, :activity_objects, :parent)
    @pagy, @activities = pagy(@activities)
  end

  def new
    @group = Group.new
    @group.build_actor
    authorize @group.actor, policy_class: GroupPolicy
  end

  def create
    @group = Group.new(group_params)
    authorize @group.actor, policy_class: GroupPolicy

    @group = GroupCreation.new(current_actor, @group).call
    redirect_to group_path(@group.actor), notice: "Group created."
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
      redirect_to group_path(@group.actor), notice: "Group updated."
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
      actor_attributes: [ :id, :name, :description, :email ]
    )
  end
end
