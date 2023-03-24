# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :notifications, only: %w(index), module: 'notifications', controller: 'main'
  end
end
