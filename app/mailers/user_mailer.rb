class UserMailer < ApplicationMailer
  # Sent to the pending address, never to the confirmed one: only whoever reads the new inbox can
  # activate it.
  def email_confirmation(user)
    @user = user
    @confirmation_url = email_confirmation_url(user.generate_token_for(:email_confirmation))
    @expiry_hours = User::EMAIL_CONFIRMATION_EXPIRY.in_hours.to_i

    log_confirmation_url if Rails.env.development?

    mail to: user.unconfirmed_email
  end

  private
    # Quoted-printable breaks the long URL across lines wherever the rendered mail is written,
    # so it cannot be copied from there. PROJECT.md allows exposing the link in development.
    def log_confirmation_url
      valid_until = I18n.l(User::EMAIL_CONFIRMATION_EXPIRY.from_now, format: :short)

      Rails.logger.info <<~CONFIRMATION
        ╭──── EventDesk · E-Mail-Bestätigung ────
        │ Für:     #{@user.unconfirmed_email}
        │ Gültig:  bis #{valid_until}
        │ Link:    #{@confirmation_url}
        ╰────────────────────────────────────────
      CONFIRMATION
    end
end
