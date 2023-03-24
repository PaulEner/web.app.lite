# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :account_sharings, only: %w(index), module: 'account_sharings', controller: 'main'
  end
end
