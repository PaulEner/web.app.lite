Rails.application.routes.draw do
  scope module: 'ftps_setting' do
    scope :ftps do
      get '/edit/:type', to: 'user#edit', as: 'edit_ftps'
      patch '/', to: 'user#update', as: 'update_ftps'
      put '/', to: 'user#create', as: 'create_ftps'
      delete '/:type', to: 'user#delete', as: 'destroy_ftps'
    end

    resources :organizations, only: [] do
      patch 'ftps/:type', to: 'organization#update', as: 'update_ftps'
      delete 'ftps/:type', to: 'organization#destroy', as: 'destroy_ftps'
      post  'ftps/fetch_now/:type', to: 'organization#fetch_now', as: 'ftps_fetch_now'
    end
  end
end