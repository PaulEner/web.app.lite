# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    namespace :orders do
      get '/', to: 'main#index', as: 'index'
    end
  end
end
