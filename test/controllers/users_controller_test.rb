require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  VALID = {
    name: "Nora Neukundin",
    email_address: "nora@example.com",
    password: "sicherespasswort",
    password_confirmation: "sicherespasswort"
  }.freeze

  test "new is reachable without a session" do
    get new_user_path

    assert_response :success
  end

  test "create registers the user and starts a session" do
    assert_difference -> { User.count }, 1 do
      post users_path, params: { user: VALID }
    end

    assert_redirected_to root_url
    assert cookies[:session_id].present?

    user = User.find_by(email_address: "nora@example.com")
    assert_equal "Nora Neukundin", user.name
    assert user.authenticate(VALID[:password])
  end

  test "create assigns role user" do
    post users_path, params: { user: VALID }

    assert_equal "user", User.find_by(email_address: "nora@example.com").role
  end

  test "create ignores a submitted role" do
    post users_path, params: { user: VALID.merge(role: "admin") }

    assert_equal "user", User.find_by(email_address: "nora@example.com").role
  end

  test "create rejects an email address that is already taken" do
    assert_no_difference -> { User.count } do
      post users_path, params: { user: VALID.merge(email_address: users(:one).email_address) }
    end

    assert_response :unprocessable_content
    assert_nil cookies[:session_id].presence
  end

  test "create rejects a password shorter than the minimum" do
    short = "kurz123"

    assert_no_difference -> { User.count } do
      post users_path, params: { user: VALID.merge(password: short, password_confirmation: short) }
    end

    assert_response :unprocessable_content
  end

  test "create rejects a mismatched password confirmation" do
    assert_no_difference -> { User.count } do
      post users_path, params: { user: VALID.merge(password_confirmation: "etwasanderes1234") }
    end

    assert_response :unprocessable_content
  end

  test "create lists the errors centrally and leaves the fields unwrapped" do
    post users_path, params: { user: VALID.merge(name: "") }

    assert_select ".form-errors__item", I18n.t("errors.format",
      attribute: User.human_attribute_name(:name),
      message: I18n.t("errors.messages.blank"))
    assert_select ".field_with_errors", false,
      "ActionView's global field wrapper is disabled in config/application.rb"
  end

  test "create rejects a blank name" do
    assert_no_difference -> { User.count } do
      post users_path, params: { user: VALID.merge(name: "") }
    end

    assert_response :unprocessable_content
  end
end
