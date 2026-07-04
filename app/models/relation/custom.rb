# == Schema Information
#
# Table name: relations
#
#  id            :bigint           not null, primary key
#  name          :string           not null
#  receiver_type :string
#  sender_type   :string
#  type          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  actor_id      :bigint
#  parent_id     :bigint
#
# Indexes
#
#  index_relations_on_actor_id   (actor_id)
#  index_relations_on_parent_id  (parent_id)
#
# Foreign Keys
#
#  fk_rails_...  (actor_id => actors.id) ON DELETE => restrict
#  fk_rails_...  (parent_id => relations.id) ON DELETE => nullify
#

# A user-defined {Relation}, owned by an {Actor}. Every actor gets its own set of custom
# relations (e.g. "friend", "colleague") seeded from configuration on creation, and can give
# each a name and a set of {Permission Permissions}.
#
# Custom relations are the ones subjects pick when connecting to others through
# {Actor#connect_to}.
#
# @see Relation      The STI base class.
# @see Actor#relation_customs
class Relation::Custom < Relation
  belongs_to :actor

  validates :name, presence: true
  validates :actor_id, presence: true
  validates :name, uniqueness: { scope: :actor_id }

  # Custom relations owned by actor +a+.
  #
  # @param a [Actor, Integer] the owning actor (or its id).
  # @return [ActiveRecord::Relation<Relation::Custom>]
  scope :actor, ->(a) { where(actor_id: Actor.normalize_id(a)) }

  before_create :initialize_sender_type

  class << self
    # Seeds the default custom relations for +actor+ from
    # +SocialStream.custom_relations+, wiring up their permissions and parent hierarchy.
    #
    # Invoked from {Actor}'s +after_create+ callback.
    #
    # @param actor [Actor] the actor to seed relations for.
    # @return [Array<Relation::Custom>] the created relations.
    # @raise [RuntimeError] when no relations are configured for the subject type.
    def defaults_for(actor)
      subject_type = actor.subject.class.to_s.underscore

      cfg_rels = SocialStream.custom_relations.with_indifferent_access[subject_type]
      raise "Undefined relations for subject type #{subject_type}" if cfg_rels.nil?

      rels = {}

      cfg_rels.each_pair do |name, cfg_rel|
        rels[name] = create!(
          actor: actor,
          name: cfg_rel[:name],
          receiver_type: cfg_rel[:receiver_type]
        )

        if (ps = cfg_rel[:permissions]).present?
          ps.each do |p|
            p.push(nil) if p.size == 1
            rels[name].permissions << Permission.find_or_create_by(action: p[0], object: p[1])
          end
        end
      end

      cfg_rels.each_pair do |name, cfg_rel|
        rels[name].update_column(:parent_id, rels[cfg_rel["parent"]]&.id)
      end

      rels.values
    end
  end

  # The {#actor}'s {Actor#subject subject} that owns this relation.
  #
  # @return [Profile, Group, Site]
  def subject
    actor.subject
  end

  # The permissions that may be assigned to this relation, based on the owner's subject type.
  #
  # @return [Array] configured [action, object] permissions.
  def available_permissions
    Permission.available(subject)
  end

  private

  # +before_create+ callback: derives +sender_type+ from the owning actor's subtype.
  def initialize_sender_type
    return if actor.blank?
    self.sender_type = actor.actorable_type
  end
end
