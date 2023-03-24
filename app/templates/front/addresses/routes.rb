Rails.application.routes.draw do
  scope module: 'addresses' do
    post 'addresses/update_all', to: 'main#update_all'
    delete 'addresses/destroy/:id', to: 'main#destroy', as: 'destroy_addresses'

    resources :addresses, controller: 'main'

    get 'organizations/:organization_id/customers/:customer_id/addresses', to: "user#index", as: 'organization_user_addresses'
  end
end