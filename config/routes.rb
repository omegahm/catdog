Rails.application.routes.draw do
  root "home#show"

  resources :games, only: %i[create show] do
    scope module: :games do
      resource :join, only: :create
      resource :hot_seat, only: :create
      resources :moves, only: :create
      resource :seat_link, only: :show, path: "seat"
      resource :rematch, only: %i[show create destroy]
      resource :rematch_acceptance, only: :create, path: "rematch/accept"
    end
  end

  get "prototype/stats" => "stats_prototype#show" if Rails.env.development?

  get "up" => "rails/health#show", as: :rails_health_check
end
