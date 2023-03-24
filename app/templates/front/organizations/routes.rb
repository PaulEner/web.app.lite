# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'organizations' do
    resources :organizations, except: [:index, :new, :create, :destroy], controller: 'main' do
      patch :activate,              on: :member
      patch :deactivate,            on: :member
      get   :edit_options,          on: :collection
      get   :edit_software_users,   on: :member
      get   :close_confirm,         on: :member
      get   :statistic,         on: :member
      patch :update_options,        on: :collection
      patch :update_software_users, on: :member

      resources :addresses, controller: 'addresses'

      resource :period_options, only: %w(edit update), controller: 'period_options' do
        post :propagate,                  on: :member
        get  :select_propagation_options, on: :member
      end

      resources :my_unisoft do 
        
      end

      resources :api_tokens, only: %w(index create destroy)

      resource :csv_descriptor, only: %w(edit update), controller: 'csv_descriptors'

      resources :customers, only: [] do
        resources :new_provider_requests, only: %w(index new create edit update), controller: 'new_provider_requests'
        resources :bank_accounts, only: %w(index edit update), controller: 'bank_accounts'
        resources :retrieved_banking_operations, only: :index, controller: 'retrieved_banking_operations' do
          post 'force_processing', on: :collection
          post 'unlock_operations', on: :collection
        end

        resources :retrieved_documents, only: %w(index show), controller: 'retrieved_documents' do
          get   'piece',    on: :member
          get   'select',   on: :collection
          patch 'validate', on: :collection
        end

        resource :dematbox, only: %w(create destroy), controller: 'dematbox'
      end

      resource :organization_subscription, only: %w(show edit update), controller: 'subscriptions' do
        get   'select_options',    on: :collection
        patch 'propagate_options', on: :collection
      end

      #resources :pre_assignments,                   only: :index
      # resources :pre_assignment_delivery_errors,    only: :index

      # resources :pre_assignment_ignored,            only: :index do
      #   post :update_ignored_pieces, on: :collection
      # end
      # resources :pre_assignment_blocked_duplicates, only: :index do
      #   post :update_multiple, on: :collection
      # end

      # resources :account_sharings, only: %w(index new create destroy), controller: 'account_sharings' do
      #   post :accept, on: :member
      # end
    end
  end
end