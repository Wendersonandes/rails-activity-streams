# == Schema Information
#
# Table name: activities
#
#  id             :bigint           not null, primary key
#  verb           :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  author_id      :bigint           not null
#  owner_id       :bigint           not null
#  parent_id      :bigint
#  user_author_id :bigint
#
# Indexes
#
#  index_activities_on_author_id       (author_id)
#  index_activities_on_created_at      (created_at)
#  index_activities_on_owner_id        (owner_id)
#  index_activities_on_parent_id       (parent_id)
#  index_activities_on_user_author_id  (user_author_id)
#  index_activities_on_verb            (verb)
#
# Foreign Keys
#
#  fk_rails_...  (author_id => actors.id) ON DELETE => restrict
#  fk_rails_...  (owner_id => actors.id) ON DELETE => restrict
#  fk_rails_...  (parent_id => activities.id) ON DELETE => nullify
#  fk_rails_...  (user_author_id => users.id) ON DELETE => restrict
#
class Activity < ApplicationRecord
  enum :verb, { follow: 0, like: 1, make_friend: 2, post: 3, update: 4, join: 5 }, prefix: :verb

  belongs_to :author, class_name: "Actor"
  belongs_to :owner, class_name: "Actor"
  belongs_to :user_author, class_name: "User", optional: true
  belongs_to :parent, class_name: "Activity", optional: true
  has_many :children, class_name: "Activity", foreign_key: :parent_id, dependent: :destroy

  has_many :audiences, dependent: :destroy
  has_many :relations, through: :audiences
  has_many :activity_object_activities, dependent: :destroy
  has_many :activity_objects, through: :activity_object_activities

  validates :verb, presence: true
  validates :author, :owner, presence: true

  scope :authored_by, ->(actor) { where(author: Actor.normalize_id(actor)) if actor.present? }
  scope :owned_by, ->(actor) { where(owner: Actor.normalize_id(actor)) if actor.present? }
  scope :shared_with, ->(subject) {
    joins(:audiences).merge(Audience.where(relation_id: Relation.ids_shared_with(subject)))
  }
  scope :roots, -> { where(parent_id: nil) }
  scope :recent, -> { order(created_at: :desc) }

  scope :timeline, ->(actor) {
    select("DISTINCT activities.*")
      .roots
      .includes(:author, :activity_objects, :parent)
      .shared_with(actor)
      .recent
  }

  scope :home_timeline, ->(actor) {
    ids = actor.sent_active_contact_ids + [ actor.id ]
    select("DISTINCT activities.*")
      .roots
      .includes(:author, :user_author, :activity_objects, :parent)
      .where(author_id: ids)
      .shared_with(actor)
      .recent
  }

  def root?
    parent_id.nil?
  end

  def root
    parent || self
  end

  def reflexive?
    author_id == owner_id
  end

  def represented_author?
    author_id != user_author_id
  end

  def public?
    relations.where(type: "Relation::Public").exists?
  end

  def visible_to?(subject)
    return true if public?
    return true if subject.present? && relations.exists?(id: Relation.ids_shared_with(subject))
    false
  end

  def sender
    author
  end

  def receiver
    owner
  end

  def comments
    children.includes(:activity_objects)
            .joins(:activity_object_activities)
            .where(activity_object_activities: { object_type: "Comment" })
  end

  def likes
    children.where(verb: :like)
  end

  def liked_by?(actor)
    likes.exists?(author: actor)
  end

  def direct_object
    activity_objects.first
  end

  def audience
    raise "Cannot get the audience of a public activity!" if public?

    [ author, user_author&.current_profile, owner ].compact.uniq |
      Actor.joins(:received_ties)
           .merge(Tie.where(relation_id: relation_ids))
  end

  def audience_in_words(subject, details: :full)
    public_relation = relations.select { |r| r.is_a?(Relation::Public) }

    visibility, audience =
      if public_relation.present?
        [ :public, nil ]
      else
        visible_relations = relations.select { |r| r.actor_id == Actor.normalize_id(subject) }

        if visible_relations.present?
          [ :visible, visible_relations.map(&:name).uniq.join(", ") ]
        else
          [ :hidden, relations.map(&:actor).map(&:name).uniq.join(", ") ]
        end
      end

    I18n.t("activity.audience.#{visibility}.#{details}", audience: audience)
  end
end
