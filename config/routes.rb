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
end
