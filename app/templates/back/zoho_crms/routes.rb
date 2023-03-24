# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :zoho_crms, only: :index, module: 'zoho_crms', controller: 'main' do
      post 'synchronize', on: :collection
    end
  end
end
