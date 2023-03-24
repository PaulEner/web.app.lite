# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'customers' do
    resources :organizations, only: [] do
      resources :customers, controller: 'main' do
        collection do
          get   'search'
        end
        member do
          get   'edit_exact_online'
          patch 'update_exact_online'
          get   'edit_my_unisoft'
          patch 'update_my_unisoft'
          get   'edit_sage_gec'
          patch 'update_sage_gec'
          get   'edit_acd'
          patch 'update_acd'
          patch 'close_account'
          patch 'reopen_account'
          get   'edit_setting_options'
          patch 'update_setting_options'
          get   'edit_knowings_options'
          get   'account_close_confirm'
          get   'account_reopen_confirm'
          patch 'update_knowings_options'
          get   'upload_email_infos'
          get   'edit_software'
          patch 'update_software'
          get   'edit_softwares_selection'
          patch 'update_softwares_selection'
          get 'my_unisoft_societies'
          post 'associate_society'
          post 'regenerate_email_code'
        end
      end
    end
  end
end
