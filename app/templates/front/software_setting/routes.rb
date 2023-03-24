Rails.application.routes.draw do
  scope module: 'software_setting' do
    get  'organizations/:organization_id/softwares', to: "main#index", as: 'softwares_list'
    post 'organizations/:organization_id/update/:software', to: "main#update", as: 'update_software'

    post 'organizations/:organization_id/activate_software/:software', to: "main#activate", as: 'activate_software'
    post 'organizations/:organization_id/deactivate_software/:software', to: "main#deactivate", as: 'deactivate_software'

    get  'organizations/:organization_id/customers/:customer_id/softwares/:software_name', to: "user#index", as: 'organization_customer_softwares'
  end
end