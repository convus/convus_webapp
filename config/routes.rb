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

  resources :quizzes, only: %i[index show update]

  root "landing#index"

  get "/about", to: "landing#about"
  get "/privacy", to: "landing#privacy"
  get "/support", to: "landing#support"
  get "/browser_extensions", to: "landing#browser_extensions"
  get "/browser_extension", to: redirect("browser_extensions")
  get "/browser_extension_auth", to: "landing#browser_extension_auth"

  resources :ratings, except: [:show] do
    collection { post :add_topic }
  end

  resources :reviews, only: %i[index show update]

  namespace :api, defaults: {format: "json"} do
    namespace :v1 do
      resource :auth, only: [:create] do
        collection { get :status }
      end
      resources :reviews, only: [:create]
      resources :ratings, only: [:create, :show]
      resources :citations, only: %i[index show] do
        collection { post :filepath }
      end

      get "*a", to: "api_v1#not_found"
    end
  end

  namespace :admin do
    root to: "ratings#index"
    resources :users, only: [:index, :edit]
    resources :topics
    resources :topic_reviews, except: [:show]
    resources :topic_review_citations, only: %i[edit update]
    resources :citations, only: %i[index edit update show]
    resources :ratings, only: %i[index show update destroy]
    resources :publishers, only: %i[index edit update show]
    resources :quizzes, except: [:destroy]
    resources :quiz_responses, only: [:index]
  end

  authenticate :user, lambda { |u| u.developer? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end
end
