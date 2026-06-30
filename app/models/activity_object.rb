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
class ActivityObject < ApplicationRecord
  delegated_type :objectable, types: %w[Profile Group Post]

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

  scope :authored_by, ->(actor) { where(author_id: Actor.normalize_id(actor)) if actor.present? }
  scope :owned_by, ->(actor) { where(owner_id: Actor.normalize_id(actor)) if actor.present? }
  scope :shared_with, ->(subject) {
    joins(:activity_object_audiences)
      .merge(ActivityObjectAudience.where(relation_id: Relation.ids_shared_with(subject)))
  }
  scope :public_only, -> { shared_with(nil) }
  scope :trending, -> { public_only.order(like_count: :desc) }
  scope :followed_by, ->(actor) {
    return all unless actor.present?
    joins(:received_actions).merge(ActivityAction.where(actor: actor, follow: true))
  }

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

  def self.normalize_id(a)
    case a
    when Integer then a
    when Array then a.map { |e| normalize_id(e) }
    else normalize(a).id
    end
  end

  def object
    objectable
  end

  def authored_or_owned_by?(actor)
    return false if actor.blank?
    author_id == Actor.normalize_id(actor) || owner_id == Actor.normalize_id(actor)
  end

  def represented_author?
    author_id.present? && user_author_id.present? && author_id != user_author_id
  end

  def acts_as_actor?
    objectable_type == "Profile" || objectable_type == "Group"
  end

  def post_activity
    activities.joins(:activity_object_activities)
              .where(activity_object_activities: { activity_object_id: id })
              .where(verb: :post)
              .first
  end

  def likes
    Activity.where(verb: :like)
            .joins(:activity_object_activities)
            .where(activity_object_activities: { activity_object_id: id })
  end

  def liked_by?(actor)
    likes.exists?(author: actor)
  end
end
