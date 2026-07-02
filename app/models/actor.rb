# == Schema Information
#
# Table name: actors
#
#  id                    :bigint           not null, primary key
#  actorable_type        :string           not null
#  description           :text
#  email                 :string
#  name                  :string           not null
#  notification_settings :jsonb
#  slug                  :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  activity_object_id    :bigint
#  actorable_id          :bigint           not null
#
# Indexes
#
#  index_actors_on_activity_object_id               (activity_object_id)
#  index_actors_on_actorable_type_and_actorable_id  (actorable_type,actorable_id) UNIQUE
#  index_actors_on_slug                             (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (activity_object_id => activity_objects.id) ON DELETE => nullify
#
class Actor < ApplicationRecord
  extend FriendlyId

  delegated_type :actorable, types: %w[Profile Group Site]

  belongs_to :activity_object, optional: true

  has_many :sent_contacts, class_name: "Contact", foreign_key: :sender_id, dependent: :destroy
  has_many :received_contacts, class_name: "Contact", foreign_key: :receiver_id, dependent: :destroy
  has_many :sent_ties, through: :sent_contacts, source: :ties
  has_many :received_ties, through: :received_contacts, source: :ties
  has_many :sent_relations, through: :sent_ties, source: :relation
  has_many :received_relations, through: :received_ties, source: :relation
  has_many :relations, dependent: :destroy
  has_many :sent_actions, class_name: "ActivityAction", dependent: :destroy
  has_many :followings, through: :sent_actions, source: :activity_object
  has_many :authored_activities, class_name: "Activity", foreign_key: :author_id, dependent: :destroy
  has_many :owned_activities, class_name: "Activity", foreign_key: :owner_id, dependent: :destroy

  validates :name, presence: true
  validates :actorable_type, presence: true

  friendly_id :name, use: :slugged

  scope :alphabetic, -> { order(:name) }
  scope :name_search, ->(q) {
    return all unless q.present?
    where("actors.name ILIKE ?", "%#{sanitize_sql_like(q)}%")
  }
  scope :subject_type, ->(t) {
    return all unless t.present?
    types = t.split(",").map { |v| map_subject_type(v) }
    where(actorable_type: types)
  }

  after_create :create_initial_relations

  def subject
    actorable
  end

  def subject_type
    actorable_type
  end

  def self.map_subject_type(value)
    type = value.classify
    type == "User" ? "Profile" : type
  end

  def self.normalize(a)
    case a
    when Actor then a
    when Integer then find(a)
    when Array then a.map { |e| normalize(e) }
    else
      if a.respond_to?(:actor)
        a.actor || raise("Unable to normalize Actor: #{a.inspect}")
      elsif a.respond_to?(:current_profile)
        a.current_profile || raise("Unable to normalize Actor: #{a.inspect}")
      else
        raise "Unable to normalize Actor: #{a.inspect}"
      end
    end
  end

  def self.normalize_id(a)
    case a
    when Integer then a
    when Array then a.map { |e| normalize_id(e) }
    else normalize(a).id
    end
  end

  def relation_customs
    relations.where(type: "Relation::Custom")
  end

  def relation_custom(name)
    relation_customs.where("LOWER(name) = ?", name.to_s.downcase).first
  end

  def relation_ids
    relations.pluck(:id)
  end

  def received_relation_ids
    received_relations.pluck(:id)
  end

  def relations_for_select
    Relation.system_list(subject) + relation_customs
  end

  def activity_relations
    relations.allowing(:read, :activity)
  end

  def activity_relation_ids
    activity_relations.pluck(:id)
  end

  def contact_to(receiver)
    sent_contacts.find_by(receiver: receiver)
  end

  def contact_to!(receiver)
    contact_to(receiver) || sent_contacts.create!(receiver_id: Actor.normalize_id(receiver))
  end

  def contact_actors(options = {})
    direction = options[:direction] || :sent
    as = Actor.where(actorable_type: Array(options[:type] || %w[Profile Group]).map { |t| Actor.map_subject_type(t.to_s) })
    as = as.where.not(id: id) unless options[:include_self]

    as = case direction
    when :sent then as.joins(:received_ties).merge(Contact.sent_by(self))
    when :received then as.joins(:sent_ties).merge(Contact.received_by(self))
    else raise "Unknown direction: #{direction}"
    end

    as = as.merge(Tie.related_by(Relation.normalize_id(options[:relations]))) if options[:relations].present?
    as = as.merge(Relation.positive) if options[:positive] != false
    as
  end

  def contact_subjects(options = {})
    contact_actors(options).includes(:actorable).map(&:subject)
  end

  def connect_to(other_actor, as:)
    contact = sent_contacts.find_or_create_by!(receiver: other_actor)
    relation = relation_custom(as) || raise(ArgumentError, "Unknown relation: #{as}")
    contact.ties.find_or_create_by!(relation: relation)
  end

  def disconnect_from(actor, relation_name)
    relation = relation_custom(relation_name)
    return unless relation
    ties_to(actor).where(relation: relation).destroy_all
  end

  def contacts_for(relation_name)
    relation = relation_custom(relation_name)
    return Actor.none unless relation
    Actor.where(id: sent_contacts.joins(:ties).where(ties: { relation_id: relation.id }).select(:receiver_id))
  end

  def connected_with?(other_actor)
    sent_contacts.find_by(receiver: other_actor)&.established?
  end

  def has_relation_with?(actor, relation_name)
    ties_to(actor).joins(:relation).where(relations: { name: relation_name.to_s.capitalize }).exists?
  end

  def member_roles_for(group_actor)
    ties_to(group_actor).joins(:relation).pluck(:"relations.name").map(&:downcase)
  end

  def pending_contacts
    received_contacts.pending
  end

  def ties_to(subject)
    sent_ties.joins(:contact).where(contacts: { receiver_id: Actor.normalize_id(subject) })
  end

  def allow?(subject, action, object)
    ties_to(subject).allowing(action, object).exists?
  end

  def represented_by?(subject)
    return false if subject.blank?
    Actor.normalize(subject) == self ||
      ties_to(subject).joins(relation: :permissions)
                      .where(permissions: { action: :represent }).exists?
  end

  def sent_active_contact_ids
    sent_contacts.active.pluck(:receiver_id)
  end

  def suggestions(size = 1)
    candidates = Actor.where(actorable_type: SocialStream.suggested_models.map { |m| m.to_s.classify })
                       .where.not(id: sent_active_contact_ids + [ id ])
                       .order(Arel.sql("RANDOM()"))
                       .limit(size)
    candidates.map { |a| contact_to!(a) }
  end

  def to_param
    slug
  end

  private

  def create_initial_relations
    Relation::Custom.defaults_for(self)
  end
end
