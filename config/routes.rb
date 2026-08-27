Rails.application.routes.draw do
  root "events#index"

  resources :events, only: [ :index ] do
    resources :votes, only: [ :create ]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
