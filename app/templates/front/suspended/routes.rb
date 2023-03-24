Rails.application.routes.draw do
  scope module: 'suspended' do
    resource :suspended, only: :show, controller: 'main'
  end
end