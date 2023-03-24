Rails.application.routes.draw do
  scope module: 'payments' do
    resources :organizations, only: [], controller: 'main', param: :organization_id do
      get   :edit_payment,          on: :member
      post  :prepare_payment,       on: :member
      post  :confirm_payment,       on: :member
      post  :revoke_payment,        on: :member
    end

    resource :payment, controller: 'main' do
      post 'debit_mandate_notify', on: :member
      get  'debit_mandate_notify',  on: :member
    end
  end
end