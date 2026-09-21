require "test_helper"

class EmailChangesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as(@user)
  end

  test "new renders the change form" do
    get new_email_change_path

    assert_response :success
    assert_select "input[name=?]", "user[unconfirmed_email]"
  end

  test "new redirects an unauthenticated visitor to the login screen" do
    sign_out

    get new_email_change_path

    assert_redirected_to new_session_path
  end

  test "create parks the new address and sends the confirmation mail to it" do
    assert_emails 1 do
      post email_change_path, params: { user: { unconfirmed_email: "Neu@Example.com " } }
    end

    assert_redirected_to profile_path

    @user.reload
    assert_equal "neu@example.com", @user.unconfirmed_email
    assert_equal "one@example.com", @user.email_address
    assert_equal [ "neu@example.com" ], ActionMailer::Base.deliveries.last.to
  end

  test "create rejects an address that belongs to another user" do
    assert_no_emails do
      post email_change_path, params: { user: { unconfirmed_email: users(:two).email_address } }
    end

    assert_response :unprocessable_content
    assert_nil @user.reload.unconfirmed_email
  end

  test "create rejects the current address" do
    assert_no_emails do
      post email_change_path, params: { user: { unconfirmed_email: @user.email_address } }
    end

    assert_response :unprocessable_content
    assert_nil @user.reload.unconfirmed_email
  end

  test "create rejects a blank address" do
    assert_no_emails do
      post email_change_path, params: { user: { unconfirmed_email: "" } }
    end

    assert_response :unprocessable_content
    assert_nil @user.reload.unconfirmed_email
  end

  test "create replaces an older pending change" do
    @user.update!(unconfirmed_email: "erste@example.com")

    post email_change_path, params: { user: { unconfirmed_email: "zweite@example.com" } }

    assert_equal "zweite@example.com", @user.reload.unconfirmed_email
  end

  test "create ignores a submitted role" do
    post email_change_path, params: { user: { unconfirmed_email: "neu@example.com", role: "admin" } }

    assert_equal "user", @user.reload.role
  end

  test "create redirects an unauthenticated visitor to the login screen" do
    sign_out

    assert_no_emails do
      post email_change_path, params: { user: { unconfirmed_email: "neu@example.com" } }
    end

    assert_redirected_to new_session_path
  end
end
