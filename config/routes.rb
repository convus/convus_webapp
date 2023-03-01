require "sidekiq/web"

Rails.application.routes.draw do
  devise_for :users

  root "landing#index"

  get "/browser_extension", to: "landing#browser_extension"

  resources :reviews

  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web, at: "/sidekiq"
  end
end
