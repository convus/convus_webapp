require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users

  root "landing#index"

  get "/about", to: "landing#about"
  get "/privacy", to: "landing#privacy"

  resources :reviews

  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end
end
