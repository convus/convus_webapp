require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users

  resources :u, only: %i[show edit update] do
    member do
      get :following
      get :followers
    end
  end
  resources :following, only: %i[destroy] do
    member do
      get :add # Use get instead of create so it can store redirect
      post :approve
      post :unapprove
    end
  end

  root "landing#index"

  get "/about", to: "landing#about"
  get "/privacy", to: "landing#privacy"
  get "/support", to: "landing#support"
  get "/browser_extensions", to: "landing#browser_extensions"
  get "/browser_extension", to: redirect("browser_extensions")

  resources :ratings, except: [:show] do
    collection { post :add_topic }
  end

  resources :reviews, only: %i[index update]

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
    resources :topics, only: %i[index edit update show]
    resources :topic_reviews, except: [:show]
  end

  authenticate :user, lambda { |u| u.developer? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end
end
