# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'notifications' do
    resources :notifications, controller: 'main' do
      get 'latest', on: :collection
      get 'link_through', on: :member
      post 'unread_all_notifications', on: :collection
    end
  end
end