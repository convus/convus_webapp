require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users

  resources :u, only: %i[show edit update]
  resources :following, only: [:destroy] do
    member { get :add } # Use get so that it can redirect
  end

  root "landing#index"

  get "/about", to: "landing#about"
  get "/privacy", to: "landing#privacy"
  get "/support", to: "landing#support"
  get "/browser_extensions", to: "landing#browser_extensions"
  get "/browser_extension", to: redirect("browser_extensions")

  resources :reviews

  namespace :api, defaults: {format: "json"} do
    namespace :v1 do
      resource :auth, only: [:create] do
        collection { get :status }
      end
      resources :reviews, only: [:create]

      get "*a", to: "api_v1#not_found"
    end
  end

  authenticate :user, lambda { |u| u.developer? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end
end
