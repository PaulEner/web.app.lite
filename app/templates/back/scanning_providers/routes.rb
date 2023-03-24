# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :scanning_providers, module: 'scanning_providers', controller: 'main'
  end
end
