Rails.application.routes.draw do
  root "home#show"

  resource :session
  resources :users, only: %i[ new create ]

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
