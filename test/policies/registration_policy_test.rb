require "test_helper"

class RegistrationPolicyTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @other = users(:two)
    @organizer = users(:organizer)
    @admin = users(:admin)
  end

  def registration(for_user: @user, status: :published, starts_at: 1.week.from_now)
    concert = Concert.new(concert_attributes(status: status, starts_at: starts_at, ends_at: starts_at + 2.hours))
    Registration.new(user: for_user, concert: concert)
  end

  test "every role may register for an upcoming published concert" do
    [ @user, @organizer, @admin ].each do |actor|
      assert RegistrationPolicy.new(actor, registration(for_user: actor)).create?
    end
  end

  test "a draft or cancelled concert accepts no registration" do
    assert_not RegistrationPolicy.new(@user, registration(status: :draft)).create?
    assert_not RegistrationPolicy.new(@user, registration(status: :cancelled)).create?
  end

  test "a started concert accepts no registration" do
    assert_not RegistrationPolicy.new(@user, registration(starts_at: 1.hour.ago)).create?
  end

  test "a participant cancels their own registration" do
    assert RegistrationPolicy.new(@user, registration).destroy?
  end

  test "nobody cancels a foreign registration" do
    foreign = registration(for_user: @other)

    assert_not RegistrationPolicy.new(@user, foreign).destroy?
    assert_not RegistrationPolicy.new(@organizer, foreign).destroy?
    assert_not RegistrationPolicy.new(@admin, foreign).destroy?
  end

  test "a registration can no longer be cancelled once the concert started" do
    assert_not RegistrationPolicy.new(@user, registration(starts_at: 1.hour.ago)).destroy?
  end

  test "a registration of a cancelled concert can no longer be cancelled by the participant" do
    assert_not RegistrationPolicy.new(@user, registration(status: :cancelled)).destroy?
  end
end
