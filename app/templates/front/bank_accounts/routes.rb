Rails.application.routes.draw do
  scope module: 'bank_accounts' do
	  resources :bank_accounts, controller: 'main'
  end
end