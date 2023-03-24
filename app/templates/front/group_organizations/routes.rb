Rails.application.routes.draw do
  scope module: 'group_organizations' do
	resources :group_organizations, controller: 'main', controller_name: 'organization_groups'
  end
end