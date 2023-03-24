# encoding: utf-8
Rails.application.routes.draw do
	scope module: 'account_number_rules' do
    resources :organizations, only: [] do
      resources :account_number_rules, controller: 'main' do
        patch   'import',                               on: :collection
        get     'import_form',                          on: :collection
        get     'import_model',                         on: :collection
        post    'export_or_destroy',                    on: :collection
        post    'update_skip_accounting_plan_accounts', on: :collection
      end
    end
  end
end