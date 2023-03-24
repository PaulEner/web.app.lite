# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'reminder_emails' do
  	resources :organizations, only: [] do
	    resources :reminder_emails, controller: 'main' do
		    post 'deliver', on: :member
		  end
		end
  end
end