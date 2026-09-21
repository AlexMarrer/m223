class ProfilesController < ApplicationController
  before_action :set_user

  def show
  end

  def update
    if @user.update(profile_params)
      redirect_to profile_path, notice: t(".updated")
    else
      render :show, status: :unprocessable_content
    end
  end

  private
    # The profile always works on the signed-in user and never looks one up by id.
    def set_user
      @user = Current.user
    end

    # Only the name. The role is an admin's to change, and a new email address has to go through
    # the confirmation flow, so neither may be assignable here.
    def profile_params
      params.expect(user: [ :name ])
    end
end
