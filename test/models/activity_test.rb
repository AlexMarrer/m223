require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  setup do
    @concert = Concert.create!(concert_attributes)
  end

  test "belongs to an actor and a concert" do
    activity = Activity.create!(actor: users(:organizer), concert: @concert, action: "published")

    assert_equal users(:organizer), activity.actor
    assert_equal @concert, activity.concert
    assert_includes users(:organizer).activities, activity
    assert_includes @concert.activities, activity
  end

  test "requires an actor, a concert and an action" do
    activity = Activity.new
    assert_not activity.valid?
    assert_includes activity.errors.attribute_names, :actor
    assert_includes activity.errors.attribute_names, :concert
    assert_includes activity.errors.attribute_names, :action
  end

  test "stores optional details" do
    activity = Activity.create!(
      actor: users(:organizer),
      concert: @concert,
      action: "updated",
      details: '{"capacity":{"old":100,"new":80}}'
    )

    assert_equal '{"capacity":{"old":100,"new":80}}', activity.reload.details
  end

  test "records when it happened" do
    activity = Activity.create!(actor: users(:organizer), concert: @concert, action: "registered")
    assert_not_nil activity.created_at
  end
end
