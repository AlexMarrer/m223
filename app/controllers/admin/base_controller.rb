# Shared base for the admin-only user management.
#
# The gate authorizes the User class before any record is looked up, so a denied request answers
# the same way whether or not the requested user exists.
class Admin::BaseController < ApplicationController
  before_action :authorize_user_management

  helper_method :own_account?

  private
    def authorize_user_management
      authorize User, :manage?
    end

    # A user who no longer exists returns to the list rather than to the start page.
    def fallback_url
      admin_users_url
    end

    def own_account?
      @user == Current.user
    end
end
