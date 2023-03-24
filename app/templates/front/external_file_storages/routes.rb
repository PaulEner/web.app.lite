Rails.application.routes.draw do
  scope module: 'external_file_storages' do
    post 'dropbox/webhook', to: 'dropbox#webhook', action: 'webhook'
    get  'dropbox/webhook', to: 'dropbox#verify', action: 'verify'

    resources :organizations, only: [] do
      resources :user, only: [] do
        resource :file_storage_authorizations, only: %w(edit update), controller: 'authorization'
      end
    end

    resource :dropbox, controller: 'dropbox' do
      get 'authorize_url', on: :member
      get 'callback',      on: :member
    end

    resource :google_drive, controller: 'google_drive' do
      post 'authorize_url', on: :member
      get  'callback',      on: :member
    end

    resource :box do
      get 'authorize_url', on: :member
      get 'callback',      on: :member
    end

    resource :external_file_storage, controller: 'main' do
      post :use,                  on: :member
      post :update_path_settings, on: :member
    end

    get 'oganizations/:organization_id/external_storages', to: "efs_organization#index", as: 'organization_efs'

    get 'oganizations/:organization_id/customers/:customer_id/external_storages', to: "efs_user#index", as: 'organization_customer_efs'
  end
end