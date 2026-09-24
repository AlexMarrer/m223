require "test_helper"

class RegistrationTest < ActiveSupport::TestCase
  setup do
    @concert = Concert.create!(concert_attributes(capacity: 10))
  end

  test "connects one user with one concert" do
    registration = Registration.create!(user: users(:one), concert: @concert)

    assert_equal users(:one), registration.user
    assert_equal @concert, registration.concert
    assert_includes @concert.registrations, registration
    assert_includes @concert.participants, users(:one)
  end

  test "requires a user and a concert" do
    registration = Registration.new
    assert_not registration.valid?
    assert_includes registration.errors.attribute_names, :user
    assert_includes registration.errors.attribute_names, :concert
  end

  test "records the registration time" do
    registration = Registration.create!(user: users(:one), concert: @concert)
    assert_not_nil registration.created_at
  end

  test "rejects a second registration of the same user for the same concert" do
    Registration.create!(user: users(:one), concert: @concert)

    duplicate = Registration.new(user: users(:one), concert: @concert)
    assert_not duplicate.valid?
    assert_includes duplicate.errors.attribute_names, :user_id
  end

  test "rejects a duplicate registration in the database even when validation is bypassed" do
    Registration.create!(user: users(:one), concert: @concert)

    assert_raises ActiveRecord::RecordNotUnique do
      Registration.insert!({ user_id: users(:one).id, concert_id: @concert.id })
    end
  end

  test "allows the same user to register for a different concert" do
    other_concert = Concert.create!(concert_attributes(title: "Zweites Konzert"))
    Registration.create!(user: users(:one), concert: @concert)

    assert Registration.new(user: users(:one), concert: other_concert).valid?
  end

  test "allows a different user to register for the same concert" do
    Registration.create!(user: users(:one), concert: @concert)

    assert Registration.new(user: users(:two), concert: @concert).valid?
  end

  test "frees a seat again when it is deleted" do
    registration = Registration.create!(user: users(:one), concert: @concert)
    assert_equal 9, @concert.reload.free_seats

    registration.destroy!
    assert_equal 10, @concert.reload.free_seats
  end

  test "withdraw removes the registration of an upcoming published concert" do
    concert = Concert.create!(published_concert_attributes)
    registration = concert.register(users(:one))

    assert registration.withdraw
    assert_not Registration.exists?(registration.id)
  end

  # Two requests that loaded the same registration before either of them withdrew it.
  test "a registration withdrawn twice is logged once" do
    concert = Concert.create!(published_concert_attributes)
    first = concert.register(users(:one))
    second = Registration.find(first.id)

    assert first.withdraw

    assert_no_difference -> { Activity.count } do
      assert_not second.withdraw
    end
    assert_equal [ I18n.t("activerecord.errors.models.registration.attributes.base.already_withdrawn") ],
                 second.errors.full_messages
  end

  test "withdraw is rejected once the concert is cancelled or has started" do
    concert = Concert.create!(published_concert_attributes)
    cancelled_registration = concert.register(users(:one))
    concert.cancel(users(:organizer))

    assert_not cancelled_registration.withdraw
    assert Registration.exists?(cancelled_registration.id)
    assert_equal [ I18n.t("activerecord.errors.models.registration.attributes.base.closed") ],
                 cancelled_registration.errors.full_messages

    started = Concert.create!(published_concert_attributes)
    started_registration = started.register(users(:two))
    started.update_columns(starts_at: 1.hour.ago, ends_at: 1.hour.from_now)

    assert_not started_registration.withdraw
    assert Registration.exists?(started_registration.id)
  end
end
