# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'pieces_errors' do
    get 'pieces/errors', to: 'main#index', as: 'pieces_errors'

    get 'pieces/ignored_pre_assignment', to: 'ignored_pre_assignment#index', as: 'ignored_pre_assignment'
    get 'pieces/duplicated_pre_assignment', to: 'duplicated_pre_assignment#index', as: 'duplicated_pre_assignment'
    get 'pieces/failed_delivery', to: 'failed_delivery#index', as: 'failed_delivery'

    post 'pieces/update_ignored_pieces', to: 'ignored_pre_assignment#update_ignored_pieces', as: 'update_ignored_pre_assignment'
    post 'pieces/update_duplicated_preseizures', to: 'duplicated_pre_assignment#update_duplicated_preseizures', as: 'update_duplicated_preseizures'
  end
end