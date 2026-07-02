require "test_helper"

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
class ActivityTest < ActiveSupport::TestCase
  setup do
    seed_permissions_and_relations
    @alice = users(:alice)
    @bob = users(:bob)
    @author = create_profile_for(@alice)
    @owner = create_profile_for(@bob)
  end

  test "verb enum maps correctly" do
    assert_equal 0, Activity.verbs[:follow]
    assert_equal 1, Activity.verbs[:like]
    assert_equal 2, Activity.verbs[:make_friend]
    assert_equal 3, Activity.verbs[:post]
    assert_equal 4, Activity.verbs[:update]
    assert_equal 5, Activity.verbs[:join]
  end

  test "validates presence of author and owner" do
    activity = Activity.new(verb: :post)
    assert_not activity.valid?
    assert_includes activity.errors[:author], "must exist"
    assert_includes activity.errors[:owner], "must exist"
  end

  test ".roots returns activities without parent" do
    parent = Activity.create!(verb: :post, author: @author, owner: @owner,
                              relation_ids: [ Relation::Public.instance.id ])
    Activity.create!(verb: :like, author: @author, owner: @owner, parent: parent,
                     relation_ids: [ Relation::Public.instance.id ])

    assert_equal 3, Activity.roots.count # 1 parent + 2 contact activities from ProfileCreation
  end

  test "#reflexive? true when author == owner" do
    activity = Activity.new(verb: :post, author: @author, owner: @author)
    assert activity.reflexive?
  end

  test "#reflexive? false when author != owner" do
    activity = Activity.new(verb: :post, author: @author, owner: @owner)
    assert_not activity.reflexive?
  end

  test "#public? true when includes Relation::Public" do
    activity = Activity.create!(verb: :post, author: @author, owner: @owner,
                                relation_ids: [ Relation::Public.instance.id ])
    assert activity.public?
  end

  test "#represented_author? true when user_author differs from author" do
    activity = Activity.create!(verb: :post, author: @author, owner: @owner,
                                user_author: @alice,
                                relation_ids: [ Relation::Public.instance.id ])
    assert activity.represented_author?
  end

  test "#children returns child activities" do
    parent = Activity.create!(verb: :post, author: @author, owner: @owner,
                              relation_ids: [ Relation::Public.instance.id ])
    child = Activity.create!(verb: :like, author: @owner, owner: @author, parent: parent,
                             relation_ids: [ Relation::Public.instance.id ])

    assert_includes parent.children, child
    assert_equal parent, child.parent
  end

  test "#liked_by? finds like child activities" do
    parent = Activity.create!(verb: :post, author: @author, owner: @owner,
                              relation_ids: [ Relation::Public.instance.id ])
    Activity.create!(verb: :like, author: @owner, owner: @author, parent: parent,
                     relation_ids: [ Relation::Public.instance.id ])

    assert parent.liked_by?(@owner)
    assert_not parent.liked_by?(@author)
  end

  test "#root returns self for root activities" do
    activity = Activity.create!(verb: :post, author: @author, owner: @owner,
                                relation_ids: [ Relation::Public.instance.id ])
    assert_equal activity, activity.root
  end
end
