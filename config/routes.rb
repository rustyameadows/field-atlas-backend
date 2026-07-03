Rails.application.routes.draw do
  root "places#index"
  resources :users, only: [ :index, :update ]

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      namespace :auth do
        post "apple", to: "apple#create"
        post "dev", to: "dev#create"
        post "refresh", to: "refresh#create"
        delete "session", to: "sessions#destroy"
      end
      get "me", to: "me#show"
      resources :devices, only: [ :create, :update ]
      get "sync", to: "sync#show"
      post "sync/operations", to: "sync_operations#create"
      resources :trips, only: [] do
        resources :invites, only: [ :create ], controller: "trip_invites"
        resources :members, only: [ :update, :destroy ], controller: "trip_members"
      end
      get "invites/:token", to: "trip_invites#show"
      post "invites/:token/accept", to: "trip_invites#accept"

      get "search", to: "search#index"
      get "place_options", to: "place_options#show"
      resources :places, only: :create
      post "place_external_identifiers", to: "place_external_identifiers#create"
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
