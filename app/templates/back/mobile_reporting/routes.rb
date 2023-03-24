# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :mobile_reporting, only: :index, module: 'mobile_reporting', controller: 'main' do
      get 'mobile_users_stats(/:month)(/:year)', action: 'download_mobile_users', on: :collection, as: :download_users
      get 'mobile_documents_stats(/:month)(/:year)', action: 'download_mobile_documents', on: :collection, as: :download_documents
    end
  end
end
