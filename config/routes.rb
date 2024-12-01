Rails.application.routes.draw do
  root 'analyzer#new'
  post '/analyze', to: 'analyzer#analyze'
  match 'batch_analyze', to: 'analyzer#batch_analyze', via: [:get, :post]
end
