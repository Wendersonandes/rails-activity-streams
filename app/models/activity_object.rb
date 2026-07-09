# == Schema Information
#
# Table name: activity_objects
#
#  id              :bigint           not null, primary key
#  comment_count   :integer          default(0)
#  description     :text
#  follower_count  :integer          default(0)
#  like_count      :integer          default(0)
#  objectable_type :string           not null
#  payload         :jsonb
#  title           :string           default("")
#  visit_count     :integer          default(0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  author_id       :bigint
#  objectable_id   :bigint           not null
#  owner_id        :bigint
#  user_author_id  :bigint
#
# Indexes
#
#  index_activity_objects_on_author_id                          (author_id)
#  index_activity_objects_on_objectable_type_and_objectable_id  (objectable_type,objectable_id) UNIQUE
#  index_activity_objects_on_owner_id                           (owner_id)
#  index_activity_objects_on_user_author_id                     (user_author_id)
#
# Foreign Keys
#
#  fk_rails_...  (author_id => actors.id) ON DELETE => restrict
#  fk_rails_...  (owner_id => actors.id) ON DELETE => restrict
#  fk_rails_...  (user_author_id => users.id) ON DELETE => restrict
#

# An {ActivityObject} is any object that receives actions: creating a {Post}, following a
# {Profile}, joining a {Group}. It is the target that {Activity Activities} and
# {ActivityAction ActivityActions} point at.
#
# == Object subtypes
# The concrete object is resolved through +delegated_type :objectable+ and can be a {Profile},
# a {Group} or a {Post}. Use {#object} to reach the delegated record and {#acts_as_actor?} to
# tell whether the object is itself an actor (profile/group).
#
# == Authorship and audience
# Unlike a bare content row, an activity object carries its own +author+, +owner+ and
# +user_author+ (see {Activity} for the meaning of these roles) and its own audience through
# {ActivityObjectAudience}, so visibility can be resolved for the object independently of any
# single activity.
#
# @see Activity        The action performed on this object.
# @see ActivityAction  Per-actor actions (e.g. follow) received by this object.
# @see Post            A common concrete object subtype.
class ActivityObject < ApplicationRecord
  delegated_type :objectable, types: %w[Profile Group Post Comment]

  belongs_to :author, class_name: "Actor", optional: true
  belongs_to :owner, class_name: "Actor", optional: true
  belongs_to :user_author, class_name: "User", optional: true

  has_many :activity_object_audiences, dependent: :destroy
  has_many :relations, through: :activity_object_audiences
  has_many :activity_object_activities, dependent: :destroy
  has_many :activities, through: :activity_object_activities
  has_many :received_actions, class_name: "ActivityAction", dependent: :destroy
  has_many :followers, through: :received_actions, source: :actor

  validates :objectable_type, presence: true

  # Objects authored by +actor+. Returns all objects when +actor+ is blank.
  #
  # @param actor [Actor, Integer, nil] the author (or its id).
  # @return [ActiveRecord::Relation<ActivityObject>]
  scope :authored_by, ->(actor) { where(author_id: Actor.normalize_id(actor)) if actor.present? }

  # Objects owned by +actor+. Returns all objects when +actor+ is blank.
  #
  # @param actor [Actor, Integer, nil] the owner (or its id).
  # @return [ActiveRecord::Relation<ActivityObject>]
  scope :owned_by, ->(actor) { where(owner_id: Actor.normalize_id(actor)) if actor.present? }

  # Objects +subject+ is allowed to reach, resolved through their {ActivityObjectAudience
  # audiences}: the relations shared with the subject plus the {Relation::Public public relation}.
  #
  # @param subject [Actor, nil] the viewer; +nil+ yields only public objects.
  # @return [ActiveRecord::Relation<ActivityObject>]
  # @see Relation.ids_shared_with
  scope :shared_with, ->(subject) {
    joins(:activity_object_audiences)
      .merge(ActivityObjectAudience.where(relation_id: Relation.ids_shared_with(subject)))
  }

  # Publicly visible objects (shared with no particular subject).
  #
  # @return [ActiveRecord::Relation<ActivityObject>]
  # @see .shared_with
  scope :public_only, -> { shared_with(nil) }

  # Public objects ordered by popularity (descending like count).
  #
  # @return [ActiveRecord::Relation<ActivityObject>]
  scope :trending, -> { public_only.order(like_count: :desc) }

  # Objects followed by +actor+ (through a {ActivityAction} with +follow: true+). Returns all
  # objects when +actor+ is blank.
  #
  # @param actor [Actor, nil] the follower.
  # @return [ActiveRecord::Relation<ActivityObject>]
  scope :followed_by, ->(actor) {
    return all unless actor.present?
    joins(:received_actions).merge(ActivityAction.where(actor: actor, follow: true))
  }

  # Coerces its argument into an {ActivityObject}.
  #
  # Accepts an {ActivityObject} (returned as-is), an id, an array (mapped element by element),
  # or any object responding to +#activity_object+.
  #
  # @param a [ActivityObject, Integer, Array, #activity_object]
  # @return [ActivityObject, Array<ActivityObject>]
  # @raise [RuntimeError] when the value cannot be resolved.
  def self.normalize(a)
    case a
    when ActivityObject then a
    when Integer then find(a)
    when Array then a.map { |e| normalize(e) }
    else a.activity_object
    end
  rescue
    raise "Unable to normalize ActivityObject: #{a.inspect}"
  end

  # Coerces its argument into an activity object id. See {.normalize} for accepted values.
  #
  # @param a [ActivityObject, Integer, Array]
  # @return [Integer, Array<Integer>]
  def self.normalize_id(a)
    case a
    when Integer then a
    when Array then a.map { |e| normalize_id(e) }
    else normalize(a).id
    end
  end

  # The delegated concrete object ({Profile}, {Group} or {Post}).
  #
  # @return [Profile, Group, Post]
  def object
    objectable
  end

  # Was +actor+ the author or owner of this object?
  #
  # @param actor [Actor, Integer, nil]
  # @return [Boolean]
  def authored_or_owned_by?(actor)
    return false if actor.blank?
    author_id == Actor.normalize_id(actor) || owner_id == Actor.normalize_id(actor)
  end

  # Was the author acting on behalf of another entity when this object was created
  # (author differs from user_author)?
  #
  # @return [Boolean]
  def represented_author?
    author_id.present? && user_author_id.present? && author_id != user_author_id
  end

  # Is the delegated object itself an actor (a {Profile} or {Group})?
  #
  # @return [Boolean]
  def acts_as_actor?
    objectable_type == "Profile" || objectable_type == "Group"
  end

  # The +post+ {Activity} that created this object.
  #
  # @return [Activity, nil]
  def post_activity
    activities.joins(:activity_object_activities)
              .where(activity_object_activities: { activity_object_id: id })
              .where(verb: :post)
              .first
  end

  # The +like+ {Activity Activities} targeting this object.
  #
  # @return [ActiveRecord::Relation<Activity>]
  def likes
    Activity.where(verb: :like)
            .joins(:activity_object_activities)
            .where(activity_object_activities: { activity_object_id: id })
  end

  # Has +actor+ liked this object?
  #
  # @param actor [Actor]
  # @return [Boolean]
  def liked_by?(actor)
    likes.exists?(author: actor)
  end

  # Can +subject+ view this activity object?
  # @param subject [Actor, nil]
  # @return [Boolean]
  def visible_to?(subject)
    return true if acts_as_actor?

    if post_activity.present?
      post_activity.visible_to?(subject)
    else
      return true if authored_or_owned_by?(subject)
      relations.where(type: "Relation::Public").exists? || (subject.present? && relations.exists?(id: Relation.ids_shared_with(subject)))
    end
  end
end
