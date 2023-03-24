# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'groups' do
  	resources :organizations, only: [] do
		  resources :groups, controller: 'main'
		end
  end
end