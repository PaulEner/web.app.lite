Rails.application.routes.draw do
  scope module: 'boxes' do
    resource :box, controller: 'main' do
      get 'authorize_url', on: :member
      get 'callback',      on: :member
    end
  end
end