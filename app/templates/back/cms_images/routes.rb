# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :cms_images, module: 'cms_images', controller: 'main'
  end
end
