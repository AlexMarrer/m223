require "test_helper"

class Concerts::CancellationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @concert = Concert.create!(published_concert_attributes)
  end

  test "an admin cancels a published concert and its registrations stay" do
    @concert.register(users(:one))
    sign_in_as users(:admin)

    post concert_cancellation_path(@concert)

    assert_redirected_to concert_url(@concert)
    assert @concert.reload.cancelled?
    assert_equal 1, @concert.registrations.count
  end

  test "a started concert can no longer be cancelled" do
    @concert.update_columns(starts_at: 1.hour.ago, ends_at: 1.hour.from_now)
    sign_in_as users(:organizer)

    post concert_cancellation_path(@concert)

    assert_redirected_to root_url
    assert @concert.reload.published?
  end

  test "a participant may not cancel a concert" do
    sign_in_as users(:one)

    post concert_cancellation_path(@concert)

    assert_redirected_to root_url
    assert_equal I18n.t("authorization.denied"), flash[:alert]
    assert @concert.reload.published?
  end
end
