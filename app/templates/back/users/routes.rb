# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
     resources :users, except: %w(new create edit destroy), module: 'users', controller: 'main' do
      get  'search_by_code',                   on: :collection
      post 'send_reset_password_instructions', on: :member
    end
  end
end
