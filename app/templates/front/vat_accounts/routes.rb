Rails.application.routes.draw do
  scope module: 'vat_accounts' do
    resources :organizations, only: [] do
      resources :customers, only: [] do
        resource :accounting_plan, only: [] do
          resources :vat_accounts, controller: 'main' do
            # get   'edit_multiple',   on: :collection
            # patch 'update_multiple', on: :collection
          end
        end
      end
    end
  end
end