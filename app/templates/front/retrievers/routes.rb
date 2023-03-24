Rails.application.routes.draw do
  scope module: 'retrievers' do
    post 'retriever/create', to: "configuration_steps#create", as: 'retriever_create_connector'
    post 'retriever/budgea_step2', to: "configuration_steps#budgea_step2", as: 'retriever_budgea_step2'
    post 'retriever/budgea_step3', to: "configuration_steps#budgea_step3", as: 'retriever_budgea_step3'
    post 'retriever/budgea_step4', to: "configuration_steps#budgea_step4", as: 'retriever_budgea_step4'

    post 'retriever/api_config', to: "configuration_steps#api_config", as: 'retriever_api_configs'
    post 'retriever/account_infos', to: "configuration_steps#account_infos", as: 'retriever_account_infos'

    post 'retriever/create_budgea_user', to: "configuration_steps#create_budgea_user", as: 'retriever_create_budgea_user'
    post 'retriever/create_bank_accounts', to: "configuration_steps#create_bank_accounts", as: 'retriever_create_bank_accounts'
    post 'retriever/my_accounts', to: "configuration_steps#my_accounts", as: 'retriever_my_accounts'
    post 'retriever/add_infos', to: "configuration_steps#add_infos", as: 'retriever_add_infos'

    post 'retriever/retriever_infos', to: "configuration_steps#retriever_infos", as: 'retriever_infos'
    post 'retriever/destroy', to: "configuration_steps#destroy", as: 'retriever_destroy'
    post 'retriever/trigger', to: "configuration_steps#trigger", as: 'retriever_trigger'
    post 'retriever/update_budgea_error_message', to: "configuration_steps#update_budgea_error_message", as: 'retriever_update_budgea_error_message'

    get  'retriever/callback', to: 'budgea_callbacks#callback', as: 'retriever_callback'
    post 'retriever/callback', to: 'budgea_callbacks#callback'
    post 'retriever/fetch_webauth_url', to: 'budgea_callbacks#fetch_webauth_url', as: 'retriever_fetch_webauth_url'
    post 'retriever/user_synced', to: 'budgea_callbacks#user_synced', as: 'retriever_user_synced'
    post 'retriever/user_deleted', to: 'budgea_callbacks#user_deleted', as: 'retriever_user_deleted'
    post 'retriever/connection_deleted', to: 'budgea_callbacks#connection_deleted', as: 'retriever_connection_deleted'

    get 'bridge/callback',   to: 'bridge#callback', as: 'bridge_callback'
    get 'bridge/setup_item', to: 'bridge#setup_item', as: 'bridge_setup'
    get 'bridge/delete_item', to: 'bridge#delete_item', as: 'bridge_delete'
  end

  resources :retrievers, module: 'retrievers', controller: 'main' do
    get 'new_internal', on: :collection
    get 'edit_internal', on: :collection
    get  'list',                     on: :collection
    get  'subscription',             on: :collection
    post 'export_connector_to_xls',   on: :collection
    get  'get_connector_xls(/:key)', action: 'get_connector_xls',   on: :collection
  end
end