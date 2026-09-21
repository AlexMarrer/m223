# Admin-initiated email change. It uses the same model API as the self-service flow in
# EmailChangesController, so the new address becomes active only once the affected user opens
# the confirmation link sent to it.
class Admin::EmailChangesController < Admin::BaseController
  before_action :set_user

  def create
    @user.assign_attributes(email_change_params)

    if @user.save(context: :email_change)
      UserMailer.email_confirmation(@user).deliver_now
      redirect_to admin_users_path, notice: t(".confirmation_sent", email: @user.unconfirmed_email)
    else
      render "admin/users/edit", status: :unprocessable_content
    end
  end

  private
    def set_user
      @user = User.find(params[:user_id])
    end

    def email_change_params
      params.expect(user: [ :unconfirmed_email ])
    end
end
