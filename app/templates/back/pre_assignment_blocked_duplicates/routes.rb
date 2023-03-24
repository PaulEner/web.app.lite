# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :pre_assignment_blocked_duplicates, only: :index, module: 'pre_assignment_blocked_duplicates', controller: 'main'
  end
end
