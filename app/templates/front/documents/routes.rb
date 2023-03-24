# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'documents' do
    get '/contents/original/*all', to: 'abase#handle_bad_url'

    post 'documents/deliver_preseizures', to: 'abase#deliver_preseizures', as: 'documents_deliver_preseizures'
    post 'documents/already_exist_document', to: 'abase#already_exist_document', as: 'already_exist_document'

    get  'documents/exist_document/:id/download/', to: 'abase#exist_document', as: 'exist_document'

    get 'documents/tags', to: 'abase#get_tags', as: 'documents_tags'
    post 'documents/tags/update', to: 'abase#update_tags', as: 'documents_update_tags'

    post 'documents/export_options', to: 'abase#export_options', as: 'documents_export_options'
    post 'documents/restore', to: 'pieces#restore', as: 'restore_document'
    get 'documents/export_preseizures/:q', to: 'abase#export_preseizures', as: 'documents_export_preseizures'
    get 'documents/download_archive/:id', to: 'abase#download_archive', as: 'documents_download_archive'
    get 'documents/download_bundle/:id', to: 'abase#download_bundle', as: 'documents_download_bundle'
    get 'documents/download_selected/:ids', to: 'abase#download_selected', as: 'documents_download_selected'

    get 'documents', to: 'pieces#index', as: 'documents'
    post 'documents/delete', to: 'pieces#delete', as: 'delete_documents'
    get 'documents/:id', to: 'pieces#show', as: 'documents_details'
    

    get 'operations', to: 'operations#index', as: 'operations'
    get 'operations/:id', to: 'operations#show', as: 'operations_details'

    get 'preseizures/infos', to: 'preseizures#index', as: 'preseizures_infos'
    post 'preseizures/update', to: 'preseizures#update', as: 'preseizures_update'
    post 'preseizures/account/:id/update', to: 'preseizures#update_account', as: 'preseizures_update_account'
    get 'preseizures/accounts_list/:account_id', to: 'preseizures#accounts_list', as: 'preseizures_accounts_list'
    get 'preseizures/:id', to: 'preseizures#show', as: 'preseizures_details'
    post 'preseizures/edit_third_party', to: 'preseizures#edit_third_party', as: 'preseizures_edit_third_party'
    get 'preseizures/edit_multiple_preseizures/:ids', to: 'preseizures#edit_multiple_preseizures', as: 'preseizures_edit_multiple_preseizures'
    post 'preseizures/update_multiple_preseizures', to: 'preseizures#update_multiple_preseizures', as: 'preseizures_update_multiple_preseizures'

    post 'preseizures/new_entry', to: 'preseizures#new_entry', as: 'preseizures_new_entry'
    post 'preseizures/remove_entry', to: 'preseizures#remove_entry', as: 'preseizures_remove_entry'

    post 'pieces/update_analytics', to: 'pieces#update_analytics', as: 'update_pieces_analytics'
    get 'account/documents/pieces/:id/download/(:style)', to: 'pieces#get_piece_file', as: 'get_piece_file'
    get 'account/documents/temp_documents/:id/download/(:style)', to: 'pieces#get_temp_document_file', as: 'get_temp_document_file'
  end
  
  namespace :documents do
    resource :upload, controller: 'uploads'

    resource :uploader, controller: 'uploader' do
      get 'periods/:upload_user',  to: 'uploader#periods',  on: :collection
      get 'journals/:upload_user', to: 'uploader#journals', on: :collection
    end
  end
end