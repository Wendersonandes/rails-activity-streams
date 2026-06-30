require "test_helper"

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
class ActivityObjectTest < ActiveSupport::TestCase
  setup do
    seed_permissions_and_relations
    @alice = users(:alice)
    @bob = users(:bob)
    @actor = create_profile_for(@alice)
    @bob_actor = create_profile_for(@bob)
    @ao = @actor.activity_object
  end

  test "validates presence of objectable_type" do
    ao = ActivityObject.new(objectable_id: 1)
    assert_not ao.valid?
  end

  test "delegated_type exposes objectable" do
    assert @ao.profile?
    assert_instance_of Profile, @ao.profile
  end

  test "#authored_or_owned_by? returns true for author" do
    @ao.update!(author: @actor)
    assert @ao.authored_or_owned_by?(@actor)
  end

  test "#authored_or_owned_by? returns false for unrelated actor" do
    assert_not @ao.authored_or_owned_by?(@bob_actor)
  end

  test "#acts_as_actor? returns true for Profile type" do
    assert @ao.acts_as_actor?
  end

  test "#object returns objectable" do
    assert_equal @actor.profile, @ao.object
  end

  test ".shared_with returns visible objects" do
    ActivityObjectAudience.create!(activity_object: @ao, relation: Relation::Public.instance)
    assert_includes ActivityObject.shared_with(@actor), @ao
  end
end
