# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    namespace :organizations do
      get '/', to: "main#index"

      get '/new', to: "main#new", as: "new"
      post '/create', to: "main#create", as: "create"

      put '/suspend/:id', to: "main#suspend", as: "suspend"
      put '/unsuspend/:id', to: "main#unsuspend", as: "unsuspend"
      put '/deactivate/:id', to: "main#deactivate", as: "deactivate"

      resources :groups, controller: 'groups'
    end
  end
end
