# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :emailed_documents, only: %w(index show), module: 'emailed_documents', controller: 'main' do
      get 'show_errors', on: :member
    end
  end
end
