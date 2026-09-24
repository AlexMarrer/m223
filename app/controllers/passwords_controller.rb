# Password change for the signed-in user. It requires the current password and never sends a
# reset link by mail.
class PasswordsController < ApplicationController
  before_action :set_user
  before_action :authorize_account

  def edit
  end

  def update
    if @user.update(password_params)
      redirect_to profile_path, notice: t(".updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_user
      @user = Current.user
    end

    def authorize_account
      authorize @user, :own_account?
    end

    # password_challenge comes from has_secure_password and is validated against the stored
    # digest. That check is what rejects a wrong current password. has_secure_password skips it
    # when the challenge is nil, so an omitted or nil field is turned into a string here.
    def password_params
      params.expect(user: [ :password_challenge, :password, :password_confirmation ]).tap do |permitted|
        permitted[:password_challenge] = permitted[:password_challenge].to_s
      end
    end
end
