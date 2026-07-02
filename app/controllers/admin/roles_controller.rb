class Admin::RolesController < ApplicationController
  before_action :set_site_actor
  skip_after_action :verify_policy_scoped, only: [ :index, :create ]

  def index
    authorize @site_actor, policy_class: Admin::RolePolicy
    @admins = @site_actor.contacts_for("admin").to_a
    @editors = @site_actor.contacts_for("editor").to_a
    @moderators = @site_actor.contacts_for("moderator").to_a
    @silenced = @site_actor.contacts_for("silenced").to_a
    @banned = @site_actor.contacts_for("banned").to_a
    @total_members = @site_actor.contacts_for("member").count
  end

  def create
    authorize @site_actor, policy_class: Admin::RolePolicy
    member = find_actor(params[:actor_id])
    GroupMembershipService.new(@site_actor, member).add(role: params[:to_role] || "member")
    redirect_to admin_roles_path, notice: "Role assigned."
  end

  def update
    authorize @site_actor, policy_class: Admin::RolePolicy
    member = find_actor(params[:id])
    GroupMembershipService.new(@site_actor, member).change_role(
      from: params[:from_role],
      to: params[:to_role]
    )
    redirect_to admin_roles_path, notice: "Role updated."
  end

  private

  def set_site_actor
    @site_actor = Site.instance.actor
  end

  def find_actor(value)
    value.to_s.match?(/\A\d+\z/) ? Actor.find(value) : Actor.find_by!(slug: value)
  end
end
