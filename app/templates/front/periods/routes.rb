Rails.application.routes.draw do
  namespace :periods do
    resources :periods, path: '', controller: 'main'
  end
end