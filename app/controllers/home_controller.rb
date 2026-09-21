class HomeController < ApplicationController
  # Temporary landing page: the Authentication concern redirects to root_url after a
  # successful login, so the authenticated area needs a root to point at.
  # Task 6 replaces this with the concert list (root "concerts#index").
  def show
  end
end
