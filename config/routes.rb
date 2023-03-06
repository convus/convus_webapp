require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users

  root "landing#index"

  get "/about", to: "landing#about"
  get "/privacy", to: "landing#privacy"
  get "/browser_extensions", to: "landing#browser_extensions"

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
