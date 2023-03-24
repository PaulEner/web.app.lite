# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :retrievers, only: %w(index edit), module: 'retrievers', controller: 'main' do
      post 'fetcher', on: :collection
      get 'fetcher',  on: :collection
    end

    resources :retrievers, only: :index, module: 'retrievers', controller: 'archives' do
      get 'archives/budgea_users',      on: :collection
      get 'archives/budgea_retrievers', on: :collection
    end

    namespace :retrievers do
      get  '/services', to: 'services#index', as: 'services'
    end
  end
end
