# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    namespace :process_reporting do
      get '/process_reporting_table', to: 'main#process_reporting_table', as: 'process_reporting_table'

      get '/(/:year)(/:month)', to: 'main#index', as: 'index'
    end
  end
end
