Rails.application.routes.draw do
  get "/up", to: proc { [200, {}, ["success"]] }
  get "home/index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "home#index"
end
