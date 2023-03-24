# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'my_documents' do
    get 'my_documents', to: 'pieces#index', as: 'my_documents'
    get 'my_documents/:id', to: 'pieces#show', as: 'my_documents_show_piece_detail'
    post 'my_documents/delete', to: 'pieces#delete', as: 'my_documents_delete'
    post 'my_documents/restore', to: 'pieces#restore', as: 'my_documents_restore'

    post 'my_documents/export_options', to: 'abase#export_options', as: 'my_documents_export_options'
    get 'my_documents/get/tags', to: 'abase#get_tags', as: 'my_documents_tags'
    post 'my_documents/tags/update', to: 'abase#update_tags', as: 'my_documents_update_tags'

    post 'my_documents/update_tag_temp_documents', to: 'pieces#update_tag_temp_documents', as: 'my_documents_update_tag_temp_documents'
    get 'my_documents/download_selected_zip/:ids', to: 'abase#download_selected_zip', as: 'my_documents_download_selected_zip'

    get 'my_documents/preseizures/infos', to: 'preseizures#index', as: 'preseizures_my_documents_infos'
    post 'my_documents/deliver_preseizures', to: 'abase#deliver_preseizures', as: 'my_documents_deliver_preseizures'
    get 'my_documents/export_preseizures/:q', to: 'abase#export_preseizures', as: 'my_documents_export_preseizures'

    post 'my_documents/preseizures/update', to: 'preseizures#update', as: 'my_documents_preseizures_update'
    post 'my_documents/preseizures/account/:id/update', to: 'preseizures#update_account', as: 'my_documents_preseizures_update_account'
    get 'my_documents/preseizures/accounts_list/:account_id', to: 'preseizures#accounts_list', as: 'my_documents_preseizures_accounts_list'
    get 'my_documents/preseizures/:id', to: 'preseizures#show', as: 'my_documents_preseizures_details'
    post 'my_documents/preseizures/edit_third_party', to: 'preseizures#edit_third_party', as: 'my_documents_preseizures_edit_third_party'
    get 'my_documents/preseizures/edit_multiple_preseizures/:ids', to: 'preseizures#edit_multiple_preseizures', as: 'my_documents_preseizures_edit_multiple_preseizures'
    post 'my_documents/preseizures/update_multiple_preseizures', to: 'preseizures#update_multiple_preseizures', as: 'my_documents_preseizures_update_multiple_preseizures'

    post 'my_documents/preseizures/new_entry', to: 'preseizures#new_entry', as: 'my_documents_preseizures_new_entry'
    post 'my_documents/preseizures/remove_entry', to: 'preseizures#remove_entry', as: 'my_documents_preseizures_remove_entry'

    post 'my_documents/pieces/update_analytics', to: 'pieces#update_analytics', as: 'my_documents_update_pieces_analytics'
  end

  namespace :my_documents do
    resource :upload, controller: 'uploads'

    resource :uploader, controller: 'uploader' do
      get 'periods/:upload_user',  to: 'uploader#periods',  on: :collection
      get 'journals/:upload_user(/:is_customer)', to: 'uploader#journals', on: :collection
    end
  end
end