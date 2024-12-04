Rails.application.routes.draw do
  #directory tools
  post '/analyzer/new', to: 'analyzer#new'
  post '/analyze', to: 'analyzer#analyze'
  match '/batch_analyze', to: 'analyzer#batch_analyze', via: [:get, :post]

  #municipalities
  root 'municipalities#index'

  resources :municipalities do
    collection do
      get :search
    end
  end

  post '/request_municipality', to: 'municipalities#request_new'
  post '/subscribe_updates', to: 'municipalities#subscribe'

  get '/rankings', to: 'pages#rankings', as: :rankings
  get '/about', to: 'pages#about', as: :about

  #zoning checker
  get '/checker', to: 'zoning#checker'
end
