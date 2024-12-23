require 'sidekiq/web'

Rails.application.routes.draw do
  #directory tools
  post '/analyzer/new', to: 'analyzer#new'
  post '/analyze', to: 'analyzer#analyze'
  match '/batch_analyze', to: 'analyzer#batch_analyze', via: [:get, :post]

  #municipalities
  root 'municipalities#index'

  resources :municipalities, only: [:index, :show]

  post '/request_municipality', to: 'municipalities#request_new'
  post '/subscribe_updates', to: 'municipalities#subscribe'

  get '/rankings', to: 'pages#rankings', as: :rankings
  get '/about', to: 'pages#about', as: :about

  #zoning checker
  get '/checker', to: 'zoning#checker'

  get 'logo_fetcher/new', to: 'logo_fetcher#new'
  post 'logo_fetcher/fetch', to: 'logo_fetcher#fetch'

  # For logo fetcher
  post 'logo_fetcher/bulk_process', to: 'logo_fetcher#bulk_process'
  get 'logo_fetcher/job_status/:id', to: 'logo_fetcher#job_status'

  mount Sidekiq::Web => '/sidekiq'

  get 'kml_generator/new'
  post 'kml_generator', to: 'kml_generator#create'

  resources :documents do
    resource :chat, only: [:show] do
      post :ask
    end
  end
end
