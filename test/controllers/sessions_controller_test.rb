require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password123456" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  test "new offers the registration link and German labels" do
    get new_session_path

    assert_select "h1", I18n.t("sessions.new.heading")
    assert_select "a[href=?]", new_user_path
  end

  test "create shows one generic German message for a wrong password" do
    post session_path, params: { email_address: @user.email_address, password: "falsch" }
    follow_redirect!

    assert_select ".flash--alert", I18n.t("sessions.create.invalid_credentials")
  end

  test "create shows the same message for an unknown email address" do
    post session_path, params: { email_address: "niemand@example.com", password: "falsch" }
    follow_redirect!

    assert_select ".flash--alert", I18n.t("sessions.create.invalid_credentials")
  end

  test "destroy confirms the sign out in German" do
    sign_in_as(User.take)

    delete session_path
    follow_redirect!

    assert_select ".flash--notice", I18n.t("sessions.destroy.signed_out")
  end
end
