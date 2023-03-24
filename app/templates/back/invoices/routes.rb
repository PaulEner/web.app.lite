# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    namespace :invoices do
      get '/', to: 'main#index', as: 'index'
      get '/:id', to: 'main#show', as: 'show'

      get '/archive', to: 'main#archive', as: 'archive'
      post '/download', to: 'main#download', as: 'download'
      post '/debit_order', to: 'main#debit_order', as: 'debit_order'
    end
  end
end
