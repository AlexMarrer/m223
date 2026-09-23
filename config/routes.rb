Rails.application.routes.draw do
  root "concerts#index"

  resource :session
  resources :users, only: %i[ new create ]

  resources :concerts do
    resource :registration, only: %i[ create destroy ]

    # State changes and the participant list are resources of their own, the way the account
    # screens already model them, instead of extra verbs on ConcertsController.
    scope module: :concerts do
      resource :publication, only: :create
      resource :cancellation, only: :create
      resources :participants, only: :index
    end
  end

  resources :registrations, only: :index

  # S14. The feed is read-only and covers every concert, so it hangs off the root and not off a
  # single concert.
  resources :activities, only: :index

  resource :profile, only: %i[ show update ]
  resource :password, only: %i[ edit update ]
  resource :email_change, only: %i[ new create ]
  resources :email_confirmations, only: :show, param: :token

  namespace :admin do
    resources :users, only: %i[ index edit update ] do
      resource :email_change, only: :create
    end
  end

  # Returns 200 once the app boots without raising, for load balancers and uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check
end
