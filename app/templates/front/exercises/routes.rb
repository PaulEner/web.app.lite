# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'exercises' do
  	resources :organizations, only: [] do
      resources :customers, only: [] do
      	resources :exercises, controller: 'main'
      end
    end
  end
end