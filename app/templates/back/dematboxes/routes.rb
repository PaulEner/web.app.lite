# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :dematboxes, only: %w(index show destroy), module: 'dematboxes', controller: 'main' do
      post 'subscribe', on: :member
    end

    resources :dematbox_services, only: %w(index destroy), module: 'dematboxes', controller: 'services' do
      post 'load_from_external', on: :collection
    end

    resources :dematbox_files, only: :index, module: 'dematboxes', controller: 'files'
  end
end
