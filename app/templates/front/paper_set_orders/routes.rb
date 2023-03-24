# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'paper_set_orders' do
  	resources :organizations, only: [] do
		  resources :paper_set_orders, controller: 'main' do
	      get  'select_for_orders', on: :collection
	      post 'order_multiple',   on: :collection
	      post 'create_multiple', on: :collection
	    end
	  end
  end
end