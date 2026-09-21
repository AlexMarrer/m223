class HomeController < ApplicationController
  # Temporary landing page: the Authentication concern redirects to root_url after a
  # successful login, so the authenticated area needs a root to point at.
  # Task 6 replaces this with the concert list (root "concerts#index").
  #
  # Open to every authenticated user, so there is nothing to authorize. root has to stay that
  # way: it is where a denied request is redirected to.
  skip_after_action :verify_authorized

  def show
  end
end
