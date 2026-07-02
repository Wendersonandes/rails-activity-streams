class GroupMembershipsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index ]
  skip_after_action :verify_policy_scoped, only: [ :index, :insights, :approve_request, :reject_request, :accept_invite, :decline_invite ]
  before_action :set_group

  def index
    authorize @group_actor, policy_class: GroupPolicy
    @admins = @group_actor.contacts_for("admin").to_a
    @moderators = @group_actor.contacts_for("moderator").to_a
    @members = @group_actor.contacts_for("member").to_a
    @is_admin = current_actor && @group_actor.has_relation_with?(current_actor, "Admin")
    @pending_requests = if @is_admin
      @group_actor.received_contacts.pending.includes(:sender).to_a
    else
      Contact.none
    end
  end

  def insights
    authorize @group_actor, :manage_members?, policy_class: GroupPolicy
    @stats = build_insights
  end

  def create
    @member = params[:actor_id].present? ? find_actor(params[:actor_id]) : nil

    if @member && @member != current_actor
      authorize @group_actor, :add_member?, policy_class: GroupPolicy
      @group_actor.connect_to(@member, as: params[:role] || "member")
      redirect_to group_memberships_path(@group), notice: "Invite sent."
    else
      @member = current_actor
      authorize @group_actor, :join?, policy_class: GroupPolicy

      if @group_actor.member_roles_for(@member).any?
        return redirect_to group_memberships_path(@group), notice: "You are already a member."
      end

      if @member.contact_to(@group_actor).present?
        return redirect_to group_memberships_path(@group), notice: "Your request is already pending."
      end

      @member.connect_to(@group_actor, as: "member")
      if @group.public_group?
        @group_actor.connect_to(@member, as: "member")
        redirect_to group_memberships_path(@group), notice: "You joined the group."
      else
        redirect_to group_memberships_path(@group), notice: "Request sent. Awaiting approval."
      end
    end
  end

  def accept_invite
    authorize @group_actor, :join?, policy_class: GroupPolicy
    invite = current_actor.received_contacts.pending.find_by(sender: @group_actor)
    if invite
      current_actor.connect_to(@group_actor, as: "member")
      redirect_to group_memberships_path(@group), notice: "Invite accepted."
    else
      redirect_to group_memberships_path(@group), alert: "No pending invite found."
    end
  end

  def decline_invite
    authorize @group_actor, :join?, policy_class: GroupPolicy
    contact = current_actor.received_contacts.pending
                            .find_by(id: params[:contact_id], sender: @group_actor)
    if contact&.destroy
      redirect_to group_memberships_path(@group), notice: "Invite declined."
    else
      redirect_to group_memberships_path(@group), alert: "Invite not found."
    end
  end

  def approve_request
    authorize @group_actor, :add_member?, policy_class: GroupPolicy
    contact = @group_actor.received_contacts.pending.find(params[:contact_id])
    @group_actor.connect_to(contact.sender, as: params[:role] || "member")
    redirect_to group_memberships_path(@group), notice: "Request approved."
  end

  def reject_request
    authorize @group_actor, :add_member?, policy_class: GroupPolicy
    contact = @group_actor.received_contacts.pending.find(params[:contact_id])
    contact.destroy
    redirect_to group_memberships_path(@group), notice: "Request rejected."
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

  def build_insights
    range = 7.days.ago..Time.current
    posts = Activity.roots.where(owner: @group_actor)

    new_members = Tie.joins(:contact)
                     .where(contacts: { sender_id: @group_actor.id })
                     .where(created_at: range).count

    new_posts = posts.where(created_at: range).count

    active_authors = posts.where(created_at: range)
                          .where.not(author: @group_actor)
                          .distinct.count(:author_id)

    daily_members = Tie.joins(:contact)
                       .where(contacts: { sender_id: @group_actor.id })
                       .where(created_at: range)
                       .group("DATE(ties.created_at)")
                       .order(Arel.sql("DATE(ties.created_at)"))
                       .count

    daily_members_labeled = daily_members.transform_keys { |d| Date.parse(d.to_s).strftime("%a") }

    raw_top = posts.where.not(author: @group_actor)
                   .group(:author_id)
                   .order(Arel.sql("COUNT(*) DESC"))
                   .limit(10)
                   .count

    author_ids = raw_top.keys
    author_map = Actor.where(id: author_ids).index_by(&:id)
    top_contributors = raw_top.map { |id, count| { actor: author_map[id], count: count } }

    {
      new_members: new_members,
      new_posts: new_posts,
      active_members: active_authors,
      daily_members: daily_members_labeled,
      top_contributors: top_contributors
    }
  end

  def after_destroy_path
    @member == current_actor ? groups_path : group_memberships_path(@group)
  end

  def after_destroy_notice
    @member == current_actor ? "You left the group." : "Member removed."
  end
end
