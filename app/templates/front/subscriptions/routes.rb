Rails.application.routes.draw do
  scope module: 'subscriptions' do
    resources :organizations, only: [] do
      resources :customers, only: [] do
		    resource :subscription, controller: 'main'
      end
    end
  end
end