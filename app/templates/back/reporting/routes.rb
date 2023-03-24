# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    namespace :reporting do
      get '/row_organization', to: 'main#row_organization', as: 'row_organization'
      post '/total_footer', to: 'main#total_footer', as: 'total_footer'

      get '/(:year)', to: 'main#index', as: 'root'
    end
  end
end
