# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'my_company_files' do
    post 'my_company_files/upload', to: 'callbacks#upload', as: 'my_company_files_upload'

    resources :organizations, only: [] do
      resources :mcf_users, only: :index, controller: 'users'
      resource :mcf_settings, only: %w(edit update destroy), controller: 'settings' do
        post :authorize
        get  :callback
      end

      resources :customers, only: [], controller: 'user_mcf_storage' do
        get 'my_company_files', to: 'user_mcf_storage#index', as: 'my_company_files'
        member do
          get   'edit_mcf'
          post  'retake_mcf_errors'
          patch 'update_mcf'
        end
      end
    end
  end
end