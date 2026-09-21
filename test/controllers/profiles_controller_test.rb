require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "show renders name, email address and the role of the signed-in user" do
    get profile_path

    assert_response :success
    assert_select "input[name=?][value=?]", "user[name]", @user.name
    assert_select "body", /#{@user.email_address}/
    assert_select "body", /#{I18n.t("roles.user")}/
  end

  test "show offers no way to edit the role" do
    get profile_path

    assert_select "select[name=?]", "user[role]", false
    assert_select "input[name=?]", "user[role]", false
  end

  test "show shows a pending email change" do
    @user.update!(unconfirmed_email: "neu@example.com")

    get profile_path

    assert_select ".profile__pending", /neu@example\.com/
  end

  test "show redirects an unauthenticated visitor to the login screen" do
    sign_out

    get profile_path

    assert_redirected_to new_session_path
  end

  test "update changes the name of the owner" do
    patch profile_path, params: { user: { name: "Neuer Name" } }

    assert_redirected_to profile_path
    assert_equal "Neuer Name", @user.reload.name
  end

  test "update ignores a submitted role" do
    patch profile_path, params: { user: { name: "Neuer Name", role: "admin" } }

    assert_equal "user", @user.reload.role
  end

  test "update ignores a submitted email address" do
    patch profile_path, params: {
      user: { name: "Neuer Name", email_address: "gekapert@example.com", unconfirmed_email: "gekapert@example.com" }
    }

    @user.reload
    assert_equal "one@example.com", @user.email_address
    assert_nil @user.unconfirmed_email
  end

  test "update rejects a blank name" do
    patch profile_path, params: { user: { name: "" } }

    assert_response :unprocessable_content
    assert_equal "Teilnehmer Eins", @user.reload.name
  end

  test "update redirects an unauthenticated visitor to the login screen" do
    sign_out

    patch profile_path, params: { user: { name: "Neuer Name" } }

    assert_redirected_to new_session_path
    assert_equal "Teilnehmer Eins", @user.reload.name
  end
end
