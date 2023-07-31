Rails.application.routes.draw do
  get "/up", to: proc { [200, {}, ["success"]] }
  
  resources :entries, only: %i[ index show ]
  post "micropub", to: "micropub#create"

  get "home/index"
  root "home#index"
end
