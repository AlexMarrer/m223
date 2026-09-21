class EmailChangesController < ApplicationController
  before_action :set_user
  before_action :authorize_account

  def new
  end

  def create
    @user.assign_attributes(email_change_params)

    # The :email_change context adds the presence check for unconfirmed_email. Without it a blank
    # submission would save happily and mail nobody.
    if @user.save(context: :email_change)
      UserMailer.email_confirmation(@user).deliver_now
      redirect_to profile_path, notice: t(".confirmation_sent", email: @user.unconfirmed_email)
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    def set_user
      @user = Current.user
    end

    def authorize_account
      authorize @user, :own_account?
    end

    def email_change_params
      params.expect(user: [ :unconfirmed_email ])
    end
end
