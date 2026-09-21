require "test_helper"

class ActivityPolicyTest < ActiveSupport::TestCase
  test "only organizers and admins read the activity feed" do
    assert ActivityPolicy.new(users(:organizer), Activity).index?
    assert ActivityPolicy.new(users(:admin), Activity).index?
    assert_not ActivityPolicy.new(users(:one), Activity).index?
  end
end
