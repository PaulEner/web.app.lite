# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :news, module: 'news', controller: 'main' do
      post :publish, on: :member
    end
  end
end
