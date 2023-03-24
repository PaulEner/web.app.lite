Rails.application.routes.draw do
  scope module: 'compositions' do
    resources :compositions, controller: 'main' do
    	get 'download'
      delete 'reset', on: :collection
    end
  end
end