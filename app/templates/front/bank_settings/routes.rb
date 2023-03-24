Rails.application.routes.draw do
  scope module: 'bank_settings' do
	  resources :bank_settings, only: %W(index edit update create), controller: 'main' do
      post 'should_be_disabled', action: 'mark_as_to_be_disabled',   on: :collection
    end
  end
end