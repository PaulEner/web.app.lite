Rails.application.routes.draw do
  namespace :account_sharings do
    get 'new', to: 'profile#new', as: 'new'
    post '/', to: 'profile#create', as: 'create'
    delete '/:id', to: 'profile#destroy', as: 'delete'
    get 'new_request', to: 'profile#new_request', as: 'new_request'
    post 'create_request', to: 'profile#create_request', as: 'create_request'


    get 'organization/:organization_id', to: 'organization#index', as: 'organization'
    get 'organization/:organization_id/contacts', to: 'organization#get_contacts'
    get 'organization/:organization_id/accounts', to: 'organization#get_accounts'

    get 'organization/:organization_id/new_account', to: 'organization#new_account', as: 'organization_new_account'
    post 'organization/:organization_id/accept/:id', to: 'organization#accept', as: 'organization_accept'
    post 'organization/:organization_id/create_account', to: 'organization#create_account', as: 'organization_create_account'
    delete 'organization/:organization_id/account/:id', to: 'organization#destroy_account', as: 'organization_destroy_account'

    get 'organization/:organization_id/new_contact', to: 'organization#new_contact', as: 'organization_new_contact'
    get 'organization/:organization_id/edit_contact/:id', to: 'organization#edit_contact', as: 'organization_edit_contact'
    post 'organization/:organization_id/create_contact', to: 'organization#create_contact', as: 'organization_create_contact'
    post 'organization/:organization_id/update_contact/:id', to: 'organization#update_contact'
    patch 'organization/:organization_id/update_contact/:id', to: 'organization#update_contact'
    delete 'organization/:organization_id/contact/:id', to: 'organization#destroy_contact', as: 'organization_destroy_contact'

    get 'organization/:organization_id/:id', to: 'organization#edit', as: 'organization_edit'
    post 'organization/:organization_id/:id', to: 'organization#update', as: 'organization_update'
  end
end