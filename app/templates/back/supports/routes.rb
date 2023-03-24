# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :supports, module: 'supports', controller: 'main' do
      get  'get_operations', on: :collection
      get  'get_bank_accounts_bridge', on: :collection
      get  'get_transaction_bridge', on: :collection
      get 'get_pieces', on: :collection
      get 'get_preseizures', on: :collection
      get 'get_flux_bridge', on: :collection
      get 'get_ba_free', on: :collection
      get 'get_transaction_free', on: :collection
      get 'get_temp_document', on: :collection
      get 'generate_mail', on: :collection
      
      post 'generate_password', on: :collection
      post  'get_retriever', on: :collection
      post  'get_bank_accounts', on: :collection      
      post 'switch', on: :collection
      post 'resume_me', on: :collection
      post 'resend_operation', on: :collection  
      post 'resend_to_preassignment', on: :collection
      post 'resend_delivery', on: :collection
      post 'destroy_temp_document', on: :collection
      post 'delete_fingerprint_temp_document', on: :collection
      post 'set_delivery_external', on: :collection
    end
  end
end
