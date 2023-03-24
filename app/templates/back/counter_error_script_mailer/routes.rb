# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :counter_error_script_mailer, only: :index, module: 'counter_error_script_mailer', controller: 'main' do
      post 'set_state', action: 'set_state', on: :collection
      post 'set_counter', action: 'set_counter', on: :collection
    end
  end
end
