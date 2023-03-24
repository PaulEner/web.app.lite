# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :pre_assignment_deliveries, only: %w(index show), module: 'pre_assignment_deliveries', controller: 'main'
  end
end
