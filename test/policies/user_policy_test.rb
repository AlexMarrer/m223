require "test_helper"

class UserPolicyTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @other = users(:two)
    @organizer = users(:organizer)
    @admin = users(:admin)
  end

  test "only an admin manages users" do
    assert UserPolicy.new(@admin, User).manage?
    assert_not UserPolicy.new(@organizer, User).manage?
    assert_not UserPolicy.new(@user, User).manage?
  end

  test "the action queries of the admin area follow manage?" do
    %i[ index? edit? update? ].each do |query|
      assert UserPolicy.new(@admin, @other).public_send(query), "admin should be allowed to #{query}"
      assert_not UserPolicy.new(@organizer, @other).public_send(query), "organizer should not be allowed to #{query}"
      assert_not UserPolicy.new(@user, @other).public_send(query), "user should not be allowed to #{query}"
    end
  end

  test "an admin changes another user's role but never their own" do
    assert UserPolicy.new(@admin, @other).change_role?
    assert_not UserPolicy.new(@admin, @admin).change_role?
  end

  test "an organizer changes nobody's role" do
    assert_not UserPolicy.new(@organizer, @user).change_role?
    assert_not UserPolicy.new(@organizer, @organizer).change_role?
  end

  test "own_account? holds only for the signed-in user themselves" do
    assert UserPolicy.new(@user, @user).own_account?
    assert_not UserPolicy.new(@user, @other).own_account?
  end

  test "an admin has no own_account? claim on another user" do
    assert_not UserPolicy.new(@admin, @other).own_account?
  end

  test "a policy without a user fails closed" do
    assert_raises(Pundit::NotAuthorizedError) { UserPolicy.new(nil, @user) }
  end
end
