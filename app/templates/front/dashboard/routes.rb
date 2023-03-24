# encoding: utf-8
Rails.application.routes.draw do
  scope module: 'dashboard' do
    resources :dashboard, only: :index, controller: 'main' do
      collection do
        post :choose_default_summary
        get :last_scans
        get :last_uploads
        get :last_dematbox_scans
        get :last_retrieved
        post :add_customer_to_favorite
      end
    end
  end
end
