class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  # Signing in and out has no record and no role to check: the session is the subject itself.
  skip_after_action :verify_authorized
  # Full I18n key: the lambda runs as a before_action, so lazy lookup is not reliable here.
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_session_path, alert: t("sessions.create.rate_limited") }

  def new
  end

  def create
    # authenticate_by hashes a dummy password when no record matches, so the response time does
    # not reveal whether the address exists. find_by + authenticate would return early instead.
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      # One generic message for an unknown address and a wrong password alike,
      # so the form does not reveal whether an account exists.
      redirect_to new_session_path, alert: t(".invalid_credentials")
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other, notice: t(".signed_out")
  end
end
