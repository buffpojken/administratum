# frozen_string_literal: true

Administratum::Engine.routes.draw do
  # Registers the Devise/Warden scope only; the engine has its own controllers.
  devise_for :users, class_name: "Administratum::User", singular: :administratum_user, module: :devise,
                     router_name: :administratum, skip: :all

  get "sign_in", to: "sessions#new", as: :sign_in
  post "sign_in", to: "sessions#create"
  delete "sign_out", to: "sessions#destroy", as: :sign_out
  resource :password_reset, only: %i[new create edit update]

  Administratum::Routing.draw(self)

  root to: "dashboard#index"
end
