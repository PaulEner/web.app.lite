# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'knowings' do
  	resources :organizations, only: [] do
	    resource :knowings, only: %w(new create edit update), controller: 'main'
	  end
  end
end