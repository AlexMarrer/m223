require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  CURRENT = "password123456".freeze
  NEW = "neuespasswort123".freeze

  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "the password screen stays reachable for every role" do
    [ users(:one), users(:organizer), users(:admin) ].each do |actor|
      sign_out
      sign_in_as(actor)

      get edit_password_path

      assert_response :success
    end
  end

  test "edit renders the change form" do
    get edit_password_path

    assert_response :success
    assert_select "input[name=?]", "user[password_challenge]"
  end

  test "edit redirects an unauthenticated visitor to the login screen" do
    sign_out

    get edit_password_path

    assert_redirected_to new_session_path
  end

  test "update changes the password with the correct current password" do
    patch password_path, params: {
      user: { password_challenge: CURRENT, password: NEW, password_confirmation: NEW }
    }

    assert_redirected_to profile_path
    assert @user.reload.authenticate(NEW)
  end

  test "update rejects an incorrect current password" do
    patch password_path, params: {
      user: { password_challenge: "falschespasswort", password: NEW, password_confirmation: NEW }
    }

    assert_response :unprocessable_content
    assert @user.reload.authenticate(CURRENT)
  end

  test "update rejects a blank current password" do
    patch password_path, params: {
      user: { password_challenge: "", password: NEW, password_confirmation: NEW }
    }

    assert_response :unprocessable_content
    assert @user.reload.authenticate(CURRENT)
  end

  test "update rejects a request without the current password field" do
    patch password_path, params: {
      user: { password: NEW, password_confirmation: NEW }
    }

    assert_response :unprocessable_content
    assert @user.reload.authenticate(CURRENT)
  end

  test "update rejects a nil current password" do
    patch password_path, params: {
      user: { password_challenge: nil, password: NEW, password_confirmation: NEW }
    }

    assert_response :unprocessable_content
    assert @user.reload.authenticate(CURRENT)
  end

  test "update rejects a new password shorter than the minimum" do
    short = "kurz123"

    patch password_path, params: {
      user: { password_challenge: CURRENT, password: short, password_confirmation: short }
    }

    assert_response :unprocessable_content
    assert @user.reload.authenticate(CURRENT)
  end

  test "update rejects a mismatched confirmation" do
    patch password_path, params: {
      user: { password_challenge: CURRENT, password: NEW, password_confirmation: "etwasanderes1234" }
    }

    assert_response :unprocessable_content
    assert @user.reload.authenticate(CURRENT)
  end

  test "update ignores a submitted role" do
    patch password_path, params: {
      user: { password_challenge: CURRENT, password: NEW, password_confirmation: NEW, role: "admin" }
    }

    assert_equal "user", @user.reload.role
  end

  test "update redirects an unauthenticated visitor to the login screen" do
    sign_out

    patch password_path, params: {
      user: { password_challenge: CURRENT, password: NEW, password_confirmation: NEW }
    }

    assert_redirected_to new_session_path
    assert @user.reload.authenticate(CURRENT)
  end
end
