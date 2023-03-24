# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'setups' do
    resources :organizations, only: [] do
      resources :customers, only: [] do
      	resource :setup, only: [], controller: 'main' do
          member do
            get 'next'
            get 'resume'
            get 'previous'
            get 'complete_later'
          end
        end
      end
    end
  end
end