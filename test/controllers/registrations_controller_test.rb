require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @concert = Concert.create!(published_concert_attributes(capacity: 1))
  end

  test "a participant registers for a published concert" do
    sign_in_as users(:one)

    assert_difference -> { @concert.registrations.count }, 1 do
      post concert_registration_path(@concert)
    end

    assert_redirected_to concert_url(@concert)
    assert_equal I18n.t("registrations.create.created", title: @concert.title), flash[:notice]
  end

  test "a second attempt by the same user changes nothing" do
    sign_in_as users(:one)
    post concert_registration_path(@concert)

    assert_no_difference -> { @concert.registrations.count } do
      post concert_registration_path(@concert)
    end

    assert_equal I18n.t("activerecord.errors.models.registration.attributes.base.duplicate"),
                 flash[:alert]
  end

  test "a full concert is rejected" do
    @concert.register(users(:two))
    sign_in_as users(:one)

    assert_no_difference -> { @concert.registrations.count } do
      post concert_registration_path(@concert)
    end

    assert_equal I18n.t("activerecord.errors.models.registration.attributes.base.full"),
                 flash[:alert]
  end

  test "a draft, a cancelled and a started concert are denied" do
    closed = [
      Concert.create!(concert_attributes),
      Concert.create!(published_concert_attributes(status: :cancelled)),
      Concert.create!(published_concert_attributes(starts_at: 1.hour.ago, ends_at: 1.hour.from_now))
    ]
    sign_in_as users(:one)

    closed.each do |concert|
      assert_no_difference -> { Registration.count } do
        post concert_registration_path(concert)
      end

      assert_redirected_to root_url
      assert_equal I18n.t("authorization.denied"), flash[:alert]
    end
  end

  test "a participant withdraws their own registration and may register again" do
    sign_in_as users(:one)
    @concert.register(users(:one))

    assert_difference -> { @concert.registrations.count }, -1 do
      delete concert_registration_path(@concert)
    end

    assert_difference -> { @concert.registrations.count }, 1 do
      post concert_registration_path(@concert)
    end
  end

  test "a registration of another user cannot be withdrawn" do
    @concert.register(users(:two))
    sign_in_as users(:one)

    assert_no_difference -> { @concert.registrations.count } do
      delete concert_registration_path(@concert)
    end

    assert_equal I18n.t("authorization.not_found"), flash[:alert]
  end

  test "index lists only the registrations of the signed-in user" do
    other_concert = Concert.create!(published_concert_attributes(title: "Zweites Konzert"))
    @concert.register(users(:one))
    other_concert.register(users(:two))
    sign_in_as users(:one)

    get registrations_path

    assert_response :success
    assert_select "a", text: @concert.title
    assert_select "a", text: other_concert.title, count: 0
  end

  test "index shows a concert that has already started" do
    started = Concert.create!(published_concert_attributes(title: "Vergangenes Konzert"))
    started.register(users(:one))
    started.update_columns(starts_at: 1.day.ago, ends_at: 1.day.ago + 2.hours)
    sign_in_as users(:one)

    get registrations_path

    assert_select "a", text: started.title
  end
end
