Rails.application.routes.draw do
  get "/up", to: proc { [200, {}, ["success"]] }
  
  resources :entries, only: %i[ index show ]
  get "micropub", to: "micropub#index"
  post "micropub", to: "micropub#create"
  post "micropub/media", to: "micropub#media"

  get "home/index"
  root "home#index"
end
