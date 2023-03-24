# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'news' do
  	get 'news/', to: "main#index"
  end
end