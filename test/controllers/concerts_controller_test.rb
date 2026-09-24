require "test_helper"

class ConcertsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @concert = Concert.create!(published_concert_attributes)
    @draft = Concert.create!(concert_attributes(title: "Entwurf"))
  end

  test "index renders for an authenticated user" do
    sign_in_as users(:one)

    get root_path

    assert_response :success
    assert_select "h1", I18n.t("concerts.index.heading")
  end

  test "index redirects an unauthenticated visitor to the login screen" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "login after a rejected request returns to the requested page" do
    get concert_path(@concert)
    assert_redirected_to new_session_path

    post session_path, params: { email_address: users(:one).email_address, password: "password123456" }

    assert_redirected_to concert_url(@concert)
  end

  test "index hides drafts from a participant and shows them to an organizer" do
    sign_in_as users(:one)
    get concerts_path
    assert_select "td", text: @draft.title, count: 0

    sign_out
    sign_in_as users(:organizer)
    get concerts_path
    assert_select "a", text: @draft.title
  end

  test "index offers the management controls only to organizers and admins" do
    sign_in_as users(:one)
    get concerts_path
    assert_select "a[href=?]", new_concert_path, count: 0

    sign_out
    sign_in_as users(:admin)
    get concerts_path
    assert_select "a[href=?]", new_concert_path
  end

  test "show renders a published concert with its setlist" do
    sign_in_as users(:one)

    get concert_path(@concert)

    assert_response :success
    assert_select "li", text: "Nocturne op. 9 Nr. 2"
  end

  test "show denies a draft to a participant" do
    sign_in_as users(:one)

    get concert_path(@draft)

    assert_redirected_to root_url
    assert_equal I18n.t("authorization.denied"), flash[:alert]
  end

  test "a participant may not reach the concert forms" do
    sign_in_as users(:one)

    get new_concert_path
    assert_redirected_to root_url

    get edit_concert_path(@concert)
    assert_redirected_to root_url

    assert_no_difference -> { Concert.count } do
      post concerts_path, params: { concert: concert_form_params }
    end
  end

  test "an organizer creates a draft" do
    sign_in_as users(:organizer)

    assert_difference -> { Concert.count }, 1 do
      post concerts_path, params: { concert: concert_form_params }
    end

    concert = Concert.order(:created_at).last
    assert concert.draft?
    assert_equal users(:organizer), concert.creator
    assert_redirected_to concert_url(concert)
  end

  test "a time entered in the form is Swiss local time" do
    sign_in_as users(:organizer)

    post concerts_path, params: {
      concert: concert_form_params(starts_at: "2030-07-01T20:00", ends_at: "2030-07-01T22:00")
    }

    concert = Concert.order(:created_at).last
    assert_equal Time.utc(2030, 7, 1, 18), concert.starts_at
    assert_equal "Europe/Zurich", concert.starts_at.time_zone.tzinfo.name
  end

  test "create rejects invalid values and keeps the form" do
    sign_in_as users(:organizer)

    assert_no_difference -> { Concert.count } do
      post concerts_path, params: { concert: concert_form_params(title: "", capacity: 0) }
    end

    assert_response :unprocessable_content
    assert_select ".form-errors__item"
  end

  test "an organizer edits a concert" do
    sign_in_as users(:organizer)

    patch concert_path(@concert), params: {
      concert: { title: "Neuer Titel", lock_version: @concert.lock_version }
    }

    assert_redirected_to concert_url(@concert)
    assert_equal "Neuer Titel", @concert.reload.title
  end

  test "a cancelled concert stays as it is and can no longer be edited" do
    @concert.cancel(users(:organizer))
    sign_in_as users(:organizer)

    get edit_concert_path(@concert)
    assert_redirected_to root_url

    patch concert_path(@concert), params: {
      concert: { title: "Nachträglich geändert", lock_version: @concert.lock_version }
    }

    assert_redirected_to root_url
    assert_equal I18n.t("authorization.denied"), flash[:alert]
    assert_equal "Testkonzert", @concert.reload.title
  end

  test "a stale edit is rejected and keeps the submitted values" do
    sign_in_as users(:organizer)
    stale_version = @concert.lock_version
    @concert.apply_changes({ title: "Zwischenzeitlich geändert" }, actor: users(:organizer))

    patch concert_path(@concert), params: {
      concert: { title: "Konkurrierender Titel", lock_version: stale_version }
    }

    assert_response :conflict
    assert_select ".form-errors__title", I18n.t("concerts.edit.stale")
    assert_select "input[name=?][value=?]", "concert[title]", "Konkurrierender Titel"
    assert_equal "Zwischenzeitlich geändert", @concert.reload.title
  end

  test "a capacity below the current occupancy is rejected" do
    @concert.register(users(:one))
    @concert.register(users(:two))
    sign_in_as users(:organizer)

    patch concert_path(@concert), params: {
      concert: { capacity: 1, lock_version: @concert.reload.lock_version }
    }

    assert_response :unprocessable_content
    assert_equal 2, @concert.reload.capacity
  end

  test "an organizer deletes a draft" do
    sign_in_as users(:organizer)

    assert_difference -> { Concert.count }, -1 do
      delete concert_path(@draft)
    end

    assert_redirected_to concerts_path
  end

  test "a published concert cannot be deleted" do
    sign_in_as users(:organizer)

    assert_no_difference -> { Concert.count } do
      delete concert_path(@concert)
    end

    assert_redirected_to root_url
  end

  private
    def concert_form_params(**overrides)
      starts_at = 2.weeks.from_now.change(usec: 0)

      {
        title: "Neues Konzert",
        capacity: 10,
        starts_at: starts_at.to_fs(:db),
        ends_at: (starts_at + 2.hours).to_fs(:db)
      }.merge(overrides)
    end
end
