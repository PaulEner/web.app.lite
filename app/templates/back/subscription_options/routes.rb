# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :subscription_options, except: %w(show), module: 'subscription_options', controller: 'main'
  end
end
