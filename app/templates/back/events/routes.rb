# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :events, only: %w(index show), module: 'events', controller: 'main'
  end
end
