Rails.application.routes.draw do
  # OAuth routes
  get '/auth/:provider/callback', to: 'sessions#create'
  post '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'
  delete '/logout', to: 'sessions#destroy'
  
  # API routes
  namespace :api do
    namespace :v1 do
      # Dashboard
      get 'dashboard/summary', to: 'dashboard#summary'
      get 'dashboard/actions-now', to: 'dashboard#actions_now'
      get 'dashboard/review-completed', to: 'dashboard#review_completed'
      
      # Profile
      get 'profile', to: 'profile#show'
      patch 'profile', to: 'profile#update'
      
      # Template generation
      post 'time_buckets/templates', to: 'time_bucket_templates#create'
      
      resources :time_buckets, except: [:new, :edit] do
        resources :bucket_items, except: [:new, :edit], shallow: true do
          patch :complete, on: :member
        end
      end
    end
  end
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
