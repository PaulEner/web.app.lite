# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :budgea_retriever, only: :index, module: 'budgea_retriever', controller: 'main' do
      get 'export_xls', on: :collection
      get 'export_connector_list', on: :collection
      get 'get_all_users', on: :collection
    end
  end
end
