Rails.application.routes.draw do
  scope module: 'new_provider_requests' do
    resources :new_provider_requests, only: %w(index new create edit update), controller: 'main'
  end
end