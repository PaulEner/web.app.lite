# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'ibiza' do
    resources :organizations, only: [] do
      resource :ibiza, controller: 'main', only: %w(create update) do
      	get 'setting', to: 'main#setting'
      end
      resources :ibiza_users, only: :index, controller: 'users'

      resources :customers, only: [] do
        resources :ibizabox_documents, only: %w(index show), controller: 'box_documents' do
          get   'piece',    on: :member
          get   'select',   on: :collection
          patch 'validate', on: :collection
        end

        resources :ibizabox_folders, only: %w(update), controller: 'box_folders' do
          patch 'refresh', on: :collection
        end

        resource :ibiza, controller: 'customer', only: %w(edit update)
      end
    end
  end
end