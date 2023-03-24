# encoding: utf-8
Rails.application.routes.draw do
  namespace :compta_analytics do
    post :analytics,  to: 'main#analytics', as: 'get_analytics'
  end
end