Rails.application.routes.draw do
  scope module: 'csv_descriptors' do
    #routes for organizations
      get '/organizations/:organization_id/csv_descriptor/format_setting', to: 'main#format_setting', as: 'csv_descriptor_format_setting'
      patch '/organizations/:organization_id/csv_descriptor/update', to: 'main#update', as: 'csv_descriptor_update_format'

    #routes for customers
      get '/organizations/:organization_id/csv_descriptor/:user_id/format_setting', to: 'main#format_setting', as: 'csv_descriptor_format_customer_setting'
      patch '/organizations/:organization_id/csv_descriptor/:user_id/update', to: 'main#update', as: 'csv_descriptor_update_customer_format'
      post '/organizations/:organization_id/csv_descriptor/:user_id/deactivate', to: 'main#deactivate', as: 'deactivate_custom_user_csv_descriptor'
  end
end