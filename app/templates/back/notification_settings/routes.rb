# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :notification_settings, only: %w(index), module: 'notification_settings', controller: 'main' do
      get  'edit_error',             on: :collection
      post 'update_error',           on: :collection
      get  'edit_subscription',      on: :collection
      post 'update_subscription',    on: :collection
      get  'edit_dematbox_order',    on: :collection
      post 'update_dematbox_order',  on: :collection
      get  'edit_paper_set_order',   on: :collection
      post 'update_paper_set_order', on: :collection
      get  'edit_ibiza',             on: :collection
      post 'update_ibiza',           on: :collection
      get  'edit_scans',             on: :collection
      post 'update_scans',           on: :collection
    end
  end
end
