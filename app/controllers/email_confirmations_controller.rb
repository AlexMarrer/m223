# Opened from the confirmation mail. The signed, expiring token identifies the user record and
# authenticates this action on its own, so no session is required: the affected user may read the
# mail anywhere, including when an admin initiated the change.
class EmailConfirmationsController < ApplicationController
  allow_unauthenticated_access only: :show

  def show
    user = User.find_by_token_for(:email_confirmation, params[:token])

    if user.nil?
      redirect_to after_confirmation_url, alert: t(".invalid_token")
    elsif user.confirm_email
      redirect_to after_confirmation_url, notice: t(".confirmed", email: user.email_address)
    else
      # The only way to get here: the address was taken between initiation and confirmation.
      redirect_to after_confirmation_url, alert: t(".failed")
    end
  end

  private
    # Without a session the profile would only bounce to the login screen and swallow the flash.
    def after_confirmation_url
      authenticated? ? profile_path : new_session_path
    end
end
