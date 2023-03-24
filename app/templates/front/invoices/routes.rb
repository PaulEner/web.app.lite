# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'invoices' do
  	resources :organizations, only: [] do
		  resource :invoices, only: %w(index show), controller: 'main' do
	      get 'download(/:id)', action: 'download', as: :download
	      post 'insert', action: 'insert'
	      delete 'remove', action: 'remove'
	      post 'synchronize', action: 'synchronize'
	    end
	  end
  end
end