Rails.application.routes.draw do
  scope module: 'collaborators' do
    resources :organizations, only: [] do
      resources :collaborators, controller: 'main' do
        resource :rights, only: %w(edit update), controller: 'rights'
        member do
          post   :add_to_organization
          delete :remove_from_organization
        end
      end

      resources :guest_collaborators, controller: 'guest' do
        get 'search', on: :collection
      end
    end
  end
end