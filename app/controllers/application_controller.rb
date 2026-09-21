class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  allow_browser versions: :modern
  stale_when_importmap_changes

  # Turns a forgotten authorize call into a loud failure. Controllers with nothing to authorize
  # skip this explicitly and say why.
  after_action :verify_authorized

  rescue_from Pundit::NotAuthorizedError, with: :deny_access
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private
    # Pundit looks for current_user, which this application does not have.
    def pundit_user
      Current.user
    end

    # Always the start page: sending a denied request to an overview the actor may not open
    # would run straight back into this handler.
    def deny_access
      redirect_to root_url, alert: t("authorization.denied")
    end

    def record_not_found
      redirect_to fallback_url, alert: t("authorization.not_found")
    end

    # Where an interrupted request returns to. Controllers with an overview of their own
    # override it.
    def fallback_url
      root_url
    end
end
