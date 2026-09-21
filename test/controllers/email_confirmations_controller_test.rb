require "test_helper"

class EmailConfirmationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.update!(unconfirmed_email: "neu@example.com")
    @token = @user.generate_token_for(:email_confirmation)
  end

  test "show activates the pending address" do
    sign_in_as(@user)

    get email_confirmation_path(@token)

    assert_redirected_to profile_path

    @user.reload
    assert_equal "neu@example.com", @user.email_address
    assert_nil @user.unconfirmed_email
  end

  test "show works without a session and sends the visitor to the login screen" do
    get email_confirmation_path(@token)

    assert_redirected_to new_session_path
    assert_equal "neu@example.com", @user.reload.email_address
  end

  test "show rejects an unknown token" do
    get email_confirmation_path("kein-gueltiger-token")

    assert_redirected_to new_session_path
    assert_equal "one@example.com", @user.reload.email_address
  end

  test "show rejects an expired token" do
    travel User::EMAIL_CONFIRMATION_EXPIRY + 1.minute do
      get email_confirmation_path(@token)
    end

    assert_redirected_to new_session_path
    assert_equal "one@example.com", @user.reload.email_address
  end

  test "show rejects a token that was already used" do
    get email_confirmation_path(@token)
    assert_equal "neu@example.com", @user.reload.email_address

    get email_confirmation_path(@token)

    assert_equal "neu@example.com", @user.reload.email_address
    assert_nil @user.unconfirmed_email
  end

  test "show rejects the link of a superseded change" do
    @user.update!(unconfirmed_email: "noch-neuer@example.com")

    get email_confirmation_path(@token)

    assert_equal "one@example.com", @user.reload.email_address
    assert_equal "noch-neuer@example.com", @user.unconfirmed_email
  end

  test "show keeps the pending change when the address was taken meanwhile" do
    sign_in_as(@user)
    users(:two).update!(email_address: "neu@example.com")

    get email_confirmation_path(@token)

    assert_redirected_to profile_path

    @user.reload
    assert_equal "one@example.com", @user.email_address
    assert_equal "neu@example.com", @user.unconfirmed_email
  end
end
