Rails.application.routes.draw do
  root 'analyzer#new'
  post '/analyze', to: 'analyzer#analyze'
end
