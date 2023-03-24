# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :tickets, module: 'tickets', controller: 'main' do
      get 'close', on: :collection
      get 'waiting', on: :collection
      get 'processing', on: :collection
    end
  end
end
