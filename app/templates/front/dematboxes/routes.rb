Rails.application.routes.draw do
  scope module: 'dematboxes' do
    delete '/dematbox/destroy', to: 'main#destroy', as: 'delete_dematbox'
    post '/dematbox/create', to: 'main#create', as: 'create_dematbox'
  end
end