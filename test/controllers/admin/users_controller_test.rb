require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @target = users(:one)
    sign_in_as(@admin)
  end

  test "index lists every user with name, email address and role" do
    get admin_users_path

    assert_response :success
    assert_select "body", /#{@target.name}/
    assert_select "body", /#{Regexp.escape(users(:organizer).email_address)}/
    assert_select "body", /#{I18n.t("roles.organizer")}/
  end

  test "index shows a pending email change" do
    @target.update!(unconfirmed_email: "neu@example.com")

    get admin_users_path

    assert_select ".user-list__pending", /neu@example\.com/
  end

  test "index is denied for a normal user" do
    sign_out
    sign_in_as(users(:two))

    get admin_users_path

    assert_redirected_to root_path
  end

  test "index is denied for an organizer" do
    sign_out
    sign_in_as(users(:organizer))

    get admin_users_path

    assert_redirected_to root_path
    assert_equal I18n.t("authorization.denied"), flash[:alert]
  end

  test "the user-management link is shown to an admin and to nobody else" do
    get root_path
    assert_select "a[href=?]", admin_users_path

    sign_out
    sign_in_as(users(:organizer))

    get root_path
    assert_select "a[href=?]", admin_users_path, false
  end

  test "index redirects an unauthenticated visitor to the login screen" do
    sign_out

    get admin_users_path

    assert_redirected_to new_session_path
  end

  test "edit offers a role select for another user" do
    get edit_admin_user_path(@target)

    assert_response :success
    assert_select "input[name=?][value=?]", "user[name]", @target.name
    assert_select "select[name=?]", "user[role]"
  end

  test "edit offers no role select on the admin's own account" do
    get edit_admin_user_path(@admin)

    assert_response :success
    assert_select "select[name=?]", "user[role]", false
    assert_select "input[name=?]", "user[role]", false
  end

  test "update changes the name of another user" do
    patch admin_user_path(@target), params: { user: { name: "Neuer Name" } }

    assert_redirected_to admin_users_path
    assert_equal "Neuer Name", @target.reload.name
  end

  test "update changes the role of another user" do
    patch admin_user_path(@target), params: { user: { name: @target.name, role: "organizer" } }

    assert_redirected_to admin_users_path
    assert_equal "organizer", @target.reload.role
  end

  test "update ignores a role submitted for the admin's own account" do
    patch admin_user_path(@admin), params: { user: { name: @admin.name, role: "user" } }

    assert_redirected_to admin_users_path
    assert_equal "admin", @admin.reload.role
  end

  test "update rejects an unsupported role" do
    patch admin_user_path(@target), params: { user: { name: @target.name, role: "superuser" } }

    assert_response :unprocessable_content
    assert_equal "user", @target.reload.role
  end

  test "update rejects a blank name" do
    patch admin_user_path(@target), params: { user: { name: "" } }

    assert_response :unprocessable_content
    assert_equal "Teilnehmer Eins", @target.reload.name
  end

  test "update ignores a submitted email address" do
    patch admin_user_path(@target), params: {
      user: { name: @target.name, email_address: "gekapert@example.com", unconfirmed_email: "gekapert@example.com" }
    }

    @target.reload
    assert_equal "one@example.com", @target.email_address
    assert_nil @target.unconfirmed_email
  end

  test "update is denied for an organizer" do
    sign_out
    sign_in_as(users(:organizer))

    patch admin_user_path(@target), params: { user: { name: "Gekapert", role: "admin" } }

    assert_redirected_to root_path
    @target.reload
    assert_equal "Teilnehmer Eins", @target.name
    assert_equal "user", @target.role
  end

  test "update is denied for a normal user" do
    sign_out
    sign_in_as(users(:two))

    patch admin_user_path(@target), params: { user: { name: "Gekapert", role: "admin" } }

    assert_redirected_to root_path
    @target.reload
    assert_equal "Teilnehmer Eins", @target.name
    assert_equal "user", @target.role
  end

  # The Pundit gate runs before the record is looked up, so a denied request answers the same way
  # whether or not the target exists.
  test "a denied request does not reveal whether the target user exists" do
    sign_out
    sign_in_as(users(:organizer))

    get edit_admin_user_path(@target)
    existing = [ response.status, response.location ]

    get edit_admin_user_path(id: 0)

    assert_equal existing, [ response.status, response.location ]
    assert_redirected_to root_path
  end

  test "update of a user that no longer exists redirects to the list" do
    patch admin_user_path(id: 0), params: { user: { name: "Neuer Name" } }

    assert_redirected_to admin_users_path
    assert_equal I18n.t("authorization.not_found"), flash[:alert]
  end
end
