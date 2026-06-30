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
class Relation < ApplicationRecord
  belongs_to :actor, optional: true
  belongs_to :parent, class_name: "Relation", optional: true
  has_many :children, class_name: "Relation", foreign_key: :parent_id, dependent: :nullify

  has_many :relation_permissions, dependent: :destroy
  has_many :permissions, through: :relation_permissions
  has_many :ties, class_name: "Tie", dependent: :destroy
  has_many :contacts, through: :ties
  has_many :audiences, dependent: :destroy
  has_many :activities, through: :audiences
  has_many :activity_object_audiences, dependent: :destroy

  validates :name, presence: true

  scope :positive, -> { where(type: positive_names) }
  scope :allowing, ->(action, object) {
    joins(:permissions).merge(Permission.where(action: action, object: object))
  }

  class << self
    POSITIVE_NAMES = %w[Relation::Custom Relation::Public Relation::Follow Relation::Owner Relation::LocalAdmin].freeze

    def positive_names
      POSITIVE_NAMES
    end

    def create_activity?
      true
    end

    def normalize(r, options = {})
      case r
      when Relation then r
      when String
        options[:sender]&.relation_custom(r) ||
          raise("Must provide a sender when looking up relations from name: #{r}")
      when Integer then find(r)
      when Array  then r.map { |e| normalize(e, options) }
      else raise "Unable to normalize relation #{r.class}: #{r.inspect}"
      end
    end

    def normalize_id(r, options = {})
      case r
      when Integer then r
      when Array then r.map { |e| normalize_id(e, options) }
      else normalize(r, options).id
      end
    end

    def allow(subject, action, object, options = {})
      q = select("DISTINCT relations.*")
            .joins(:contacts, :permissions)

      conds = Permission.arel_table[:action].eq(Permission.actions[action])
                       .and(Permission.arel_table[:object].eq(Permission.objects[object]))

      if action == :read && object == :activity && options[:public] != false
        conds = conds.or(Relation.arel_table[:type].eq("Relation::Public"))
      end

      if options[:in].present?
        conds = conds.and(Relation.arel_table[:id].in(normalize_id(Array(options[:in]))))
      end

      conds = conds.and(Contact.arel_table[:receiver_id].eq(Actor.normalize_id(subject)))

      q.where(conds)
    end

    def allow?(*args)
      allow(*args).exists?
    end

    def ids_shared_with(subject)
      ids = [ Relation::Public.instance.id ]

      if subject.present?
        ids += subject.relation_ids + subject.received_relation_ids
      end

      ids.uniq
    end

    def system_list(subject)
      name = subject.class.to_s.underscore
      list = SocialStream.system_relations[name] || SocialStream.system_relations[name.to_sym]
      return [] if list.blank?
      list.map { |r| "Relation::#{r.to_s.classify}".constantize.instance }
    end
  end

  def mode(st, rt)
    Relation.where(sender_type: st, receiver_type: rt)
  end

  def <=>(rel)
    return -1 if rel.is_a?(Relation::Public)
    permissions.count <=> rel.permissions.count
  end

  def positive?
    self.class.positive_names.include?(self.class.to_s)
  end

  def follow?
    permissions.follow.exists?
  end

  def available_permissions
    []
  end
end
