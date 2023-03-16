require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users

  resources :u, only: %i[show edit update] do
    member { get :following }
  end
  resources :following, only: %i[destroy] do
    member { get :add } # Use get instead of create so it can store redirect
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

  namespace :admin do
    root to: "users#index"
    resources :users, only: [:index]
  end

  authenticate :user, lambda { |u| u.developer? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end
end
