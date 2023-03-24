# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'pack_reports' do
  	resources :organizations, only: [] do
	    resources :pack_reports, only: :index, controller: 'main' do
	      post 'deliver',            on: :member
	      get  'select_to_download', on: :member
	      post 'download',           on: :member
	    end
	  end
  end
end