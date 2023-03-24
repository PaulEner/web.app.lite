Rails.application.routes.draw do
  scope module: 'accounting_plans' do
    resources :organizations, only: [] do
      resources :customers, only: [] do
        resource :accounting_plan, controller: 'main' do
          member do
            patch  :import
            post   :auto_update
            post   :ibiza_synchronize
            post   :insert_general_account
            patch  :import_fec
            get    :import_model
            get    :import_fec_processing
            delete :destroy_providers
            delete :destroy_customers
          end
        end

        resource :conterpart_account, controller: 'conterpart_account' do
          member do
            get 'accounts_list/:type', to: 'conterpart_account#accounts_list', as: 'accounts_list'
            delete 'delete', to: 'conterpart_account#delete', as: 'delete'
            post 'link', to: 'conterpart_account#link', as: 'link'
            get 'select_from_customer', to: 'conterpart_account#select_from_customer', as: 'select_from_customer'
            post 'validate_from_customer', to: 'conterpart_account#validate_from_customer', as: 'validate_from_customer'
          end
        end
      end
    end
  end
end