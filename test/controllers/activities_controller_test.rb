require "test_helper"

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @concert = Concert.create!(published_concert_attributes(capacity: 2))
    @concert.register(users(:one))
  end

  test "an organizer sees actor, concert and action of every activity" do
    sign_in_as users(:organizer)

    get activities_path

    assert_response :success
    assert_select "td", text: users(:one).name
    assert_select "td", text: I18n.t("activities.actions.registered")
    assert_select "td a", text: @concert.title
  end

  test "an admin may open the feed" do
    sign_in_as users(:admin)

    get activities_path

    assert_response :success
  end

  test "a change of a published concert is shown with its old and new value" do
    @concert.apply_changes({ capacity: 5 }, actor: users(:organizer))
    sign_in_as users(:organizer)

    get activities_path

    assert_select ".activity-list__change",
                  text: "#{Concert.human_attribute_name(:capacity)}: 2 → 5"
  end

  test "a changed start is shown as a date and not as a raw JSON value" do
    new_start = 2.weeks.from_now.change(usec: 0)
    @concert.apply_changes({ starts_at: new_start, ends_at: new_start + 2.hours },
                           actor: users(:organizer))
    sign_in_as users(:organizer)

    get activities_path

    assert_select ".activity-list__change",
                  text: /#{Regexp.escape(Concert.human_attribute_name(:starts_at))}: .* → #{Regexp.escape(I18n.l(new_start, format: :short))}/
  end

  test "a field the concert did not have before is shown as a dash" do
    @concert.apply_changes({ playlist_url: "https://example.com/playlist" }, actor: users(:organizer))
    sign_in_as users(:organizer)

    get activities_path

    assert_select ".activity-list__change",
                  text: "#{Concert.human_attribute_name(:playlist_url)}: " \
                        "#{I18n.t('activities.blank')} → https://example.com/playlist"
  end

  test "a participant may not open the feed" do
    sign_in_as users(:one)

    get activities_path

    assert_redirected_to root_url
    assert_equal I18n.t("authorization.denied"), flash[:alert]
  end

  test "a signed out request goes to the login screen" do
    get activities_path

    assert_redirected_to new_session_path
  end

  test "the navigation offers the feed to organizers only" do
    sign_in_as users(:organizer)
    get concerts_path
    assert_select "nav a[href=?]", activities_path

    sign_out
    sign_in_as users(:one)
    get concerts_path
    assert_select "nav a[href=?]", activities_path, count: 0
  end
end
