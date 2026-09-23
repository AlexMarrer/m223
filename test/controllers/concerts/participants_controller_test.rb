require "test_helper"

class Concerts::ParticipantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @concert = Concert.create!(published_concert_attributes)
    @concert.register(users(:one))
  end

  test "an organizer sees name, email address and registration time" do
    sign_in_as users(:organizer)

    get concert_participants_path(@concert)

    assert_response :success
    assert_select "td", text: users(:one).name
    assert_select "td", text: users(:one).email_address
    assert_select "td", text: I18n.l(@concert.registrations.first.created_at, format: :short)
  end

  test "an admin may open the list" do
    sign_in_as users(:admin)

    get concert_participants_path(@concert)

    assert_response :success
  end

  test "a participant may not open the list" do
    sign_in_as users(:one)

    get concert_participants_path(@concert)

    assert_redirected_to root_url
    assert_equal I18n.t("authorization.denied"), flash[:alert]
  end
end
