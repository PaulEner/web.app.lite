Rails.application.routes.draw do
  scope module: 'exact_online' do
		resource :exact_online, only: [], controller: 'main' do
      get 'authenticate', on: :member
      get 'subscribe',    on: :member
      post 'unsubscribe',  on: :member
    end

  	resources :organizations, only: [] do
	    resources :exact_online_users, only: :index, controller: 'main'
	  end
  end
end