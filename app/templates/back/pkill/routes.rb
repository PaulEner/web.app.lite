# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :pkill, only: %w(index), module: 'pkill', controller: 'main'
  end
end
