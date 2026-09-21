class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[ edit update ]

  def index
    @users = User.order(:name)
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_users_path, notice: t(".updated", name: @user.name)
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    # Nobody may change their own role, so on the admin's own account the attribute is not
    # permitted at all. The missing select in the view is only the hint, never the boundary.
    # The email address is not assignable here either — it has to go through the confirmation
    # flow in Admin::EmailChangesController.
    def user_params
      params.expect(user: own_account? ? [ :name ] : [ :name, :role ])
    end
end
