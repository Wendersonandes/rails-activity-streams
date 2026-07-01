class GroupMembershipsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index ]
  skip_after_action :verify_policy_scoped, only: [ :index ]
  before_action :set_group

  def index
    authorize @group_actor, policy_class: GroupPolicy
    @admins = @group_actor.contacts_for("admin").includes(:actorable)
    @moderators = @group_actor.contacts_for("moderator").includes(:actorable)
    @members = @group_actor.contacts_for("member").includes(:actorable)
    @is_admin = current_actor&.has_relation_with?(@group_actor, "Admin")
  end

  def create
    authorize @group_actor, :add_member?, policy_class: GroupPolicy
    @member = find_actor(params[:actor_id])
    GroupMembershipService.new(@group_actor, @member).add(role: params[:role] || "member")
    redirect_to group_memberships_path(@group), notice: "Member added."
  end

  def update
    authorize @group_actor, :change_role?, policy_class: GroupPolicy
    @member = find_actor(params[:id])
    GroupMembershipService.new(@group_actor, @member).change_role(
      from: params[:from_role],
      to: params[:to_role]
    )
    redirect_to group_memberships_path(@group), notice: "Role updated."
  end

  def destroy
    @member = find_actor(params[:id])
    if @member == current_actor
      authorize @group_actor, :leave?, policy_class: GroupPolicy
    else
      authorize @group_actor, :remove_member?, policy_class: GroupPolicy
    end
    GroupMembershipService.new(@group_actor, @member).remove(role: params[:role])
    redirect_to after_destroy_path, notice: after_destroy_notice
  end

  private

  def set_group
    @group = Group.includes(:actor).find_by!(id: params[:group_id])
    @group_actor = @group.actor
  end

  def find_actor(value)
    value.to_s.match?(/\A\d+\z/) ? Actor.find(value) : Actor.find_by!(slug: value)
  end

  def after_destroy_path
    @member == current_actor ? groups_path : group_memberships_path(@group)
  end

  def after_destroy_notice
    @member == current_actor ? "You left the group." : "Member removed."
  end
end
