require "test_helper"

class Admin::EmailChangesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @target = users(:one)
    sign_in_as(@admin)
  end

  test "create parks the new address and mails it to the affected user" do
    assert_emails 1 do
      post admin_user_email_change_path(@target), params: { user: { unconfirmed_email: "Neu@Example.com " } }
    end

    assert_redirected_to admin_users_path

    @target.reload
    assert_equal "neu@example.com", @target.unconfirmed_email
    assert_equal "one@example.com", @target.email_address
    assert_equal [ "neu@example.com" ], ActionMailer::Base.deliveries.last.to
  end

  # The whole point of the admin-initiated change: it takes effect only when the affected user
  # opens the link, and they do so without the admin's session.
  test "the affected user activates the address through the confirmation link" do
    post admin_user_email_change_path(@target), params: { user: { unconfirmed_email: "neu@example.com" } }

    token = @target.reload.generate_token_for(:email_confirmation)
    sign_out
    get email_confirmation_path(token)

    @target.reload
    assert_equal "neu@example.com", @target.email_address
    assert_nil @target.unconfirmed_email
  end

  test "create rejects an address that belongs to another user" do
    assert_no_emails do
      post admin_user_email_change_path(@target), params: { user: { unconfirmed_email: users(:two).email_address } }
    end

    assert_response :unprocessable_content
    assert_nil @target.reload.unconfirmed_email
  end

  test "create rejects the current address of the target user" do
    assert_no_emails do
      post admin_user_email_change_path(@target), params: { user: { unconfirmed_email: @target.email_address } }
    end

    assert_response :unprocessable_content
    assert_nil @target.reload.unconfirmed_email
  end

  test "create rejects a blank address" do
    assert_no_emails do
      post admin_user_email_change_path(@target), params: { user: { unconfirmed_email: "" } }
    end

    assert_response :unprocessable_content
    assert_nil @target.reload.unconfirmed_email
  end

  test "create is denied for an organizer" do
    sign_out
    sign_in_as(users(:organizer))

    assert_no_emails do
      post admin_user_email_change_path(@target), params: { user: { unconfirmed_email: "neu@example.com" } }
    end

    assert_redirected_to root_path
    assert_nil @target.reload.unconfirmed_email
  end

  test "create is denied for a normal user" do
    sign_out
    sign_in_as(users(:two))

    assert_no_emails do
      post admin_user_email_change_path(@target), params: { user: { unconfirmed_email: "neu@example.com" } }
    end

    assert_redirected_to root_path
    assert_nil @target.reload.unconfirmed_email
  end

  test "create redirects an unauthenticated visitor to the login screen" do
    sign_out

    assert_no_emails do
      post admin_user_email_change_path(@target), params: { user: { unconfirmed_email: "neu@example.com" } }
    end

    assert_redirected_to new_session_path
    assert_nil @target.reload.unconfirmed_email
  end
end
