Rails.application.routes.draw do
  scope module: 'preseizures' do
  	post '/preseizure_accounts/accounts_list', to: 'accounts#accounts_list'

    resources :organizations, only: [] do
    	resources :preseizures, only: %w(index update), controller: 'main' do
        post 'deliver', on: :member
      end

      resources :preseizure_accounts, controller: 'accounts'
    end
  end
end