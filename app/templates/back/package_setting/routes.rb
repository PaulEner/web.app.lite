# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :package_setting, only: %w(index), module: 'package_setting', controller: 'main' do
      post  'update_customers', on: :collection
      post  'rollback_customers', on: :collection
    end
  end
end
