# Shared base for the admin-only user management.
#
# The role check is the interim authorization boundary until task 5 replaces it with Pundit.
# It runs before any record is looked up, so a denied request cannot reveal whether the
# requested user exists. The RecordNotFound rescue lives here for the same reason and moves to
# ApplicationController once task 5 handles lookup failures centrally.
class Admin::BaseController < ApplicationController
  before_action :require_admin
  rescue_from ActiveRecord::RecordNotFound, with: :user_not_found

  helper_method :own_account?

  private
    def require_admin
      redirect_to root_path, alert: t("admin.not_authorized") unless Current.user&.admin?
    end

    def user_not_found
      redirect_to admin_users_path, alert: t("admin.not_found")
    end

    def own_account?
      @user == Current.user
    end
end
