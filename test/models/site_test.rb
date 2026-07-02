require "test_helper"

class SiteTest < ActiveSupport::TestCase
  test "instance returns the same record" do
    site = Site.instance
    assert_equal site.id, Site.instance.id
  end

  test "instance creates a site if none exists" do
    assert_difference "Site.count", 1 do
      Site.instance
    end
  end

  test "has an actor after instance" do
    site = Site.instance
    assert site.actor.present?
  end

  test "slug delegates to actor" do
    site = Site.instance
    assert_equal site.actor.slug, site.slug
  end

  test "instance builds actor for orphaned site" do
    orphan = Site.create!(name: "Plataforma")
    actor_count = Actor.count

    result = Site.instance
    assert_equal orphan.id, result.id
    assert result.actor.present?
    assert_equal actor_count + 1, Actor.count
  end
end
