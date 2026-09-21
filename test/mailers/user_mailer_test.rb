require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "email_confirmation goes to the pending address with a working link" do
    user = users(:one)
    user.update!(unconfirmed_email: "neu@example.com")

    mail = UserMailer.email_confirmation(user)

    assert_equal [ "neu@example.com" ], mail.to
    assert_equal I18n.t("user_mailer.email_confirmation.subject"), mail.subject

    # Decoded, because quoted-printable wraps the long URL in the encoded body.
    token = mail.text_part.decoded[%r{/email_confirmations/(\S+)}, 1]
    assert_equal user, User.find_by_token_for(:email_confirmation, token)
  end

  test "email_confirmation is never sent to the confirmed address" do
    user = users(:one)
    user.update!(unconfirmed_email: "neu@example.com")

    mail = UserMailer.email_confirmation(user)

    assert_not_includes mail.to, user.email_address
  end
end
