# == Schema Information
#
# Table name: groups
#
#  id         :bigint           not null, primary key
#  privacy    :integer          default("public_group"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# A {Group} is a collective social entity (a team, organization, community). Like {Profile}
# and {Site}, it is one of the concrete types behind {Actor}'s +delegated_type :actorable+, so
# almost all of its interaction with the network happens through its {#actor}.
#
# Membership is modeled as {Tie Ties} from the group's actor to its members, using role
# relations (owner, admin, member). Its {#privacy} controls whether the group is +public_group+
# or +private_group+.
#
# @see Actor                   The social-graph node this group delegates to.
# @see GroupMembershipService  Adds, changes and removes member roles.
class Group < ApplicationRecord
  enum :privacy, { public_group: 0, private_group: 1 }

  has_one :actor, as: :actorable, dependent: :destroy, autosave: true
  has_one :activity_object, as: :objectable, dependent: :destroy, autosave: true

  delegate :name, :name=, :email, :email=, :slug, :description, :description=,
           :notification_settings, :activity_object_id,
           to: :actor, allow_nil: true

  accepts_nested_attributes_for :actor
end
