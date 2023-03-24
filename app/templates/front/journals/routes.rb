# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'journals' do
  	resources :organizations, only: [] do
		  resources :journals, except: 'show', controller: 'main'

		  resources :customers, only: [] do
		  	resources :journals, except: %w(index show), controller: 'main' do
          post    'copy',              on: :collection
          get     'select',            on: :collection
          post    'update_analytics',  on: :collection
          post    'sync_analytics',    on: :collection
        end

			  resources :list_journals, only: %w(index), controller: 'list'
			end
		end

    post 'customers/:customer_id/journals', to: "main#add_rubric", as: 'customer_rubric_addition'
		get 'organizations/:organization_id/customers/:customer_id/journals', to: "user#index", as: 'organization_user_journals'
  end
end