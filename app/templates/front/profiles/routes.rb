Rails.application.routes.draw do
  scope module: 'profiles' do
    resource :profiles, controller: 'main' do
      post '/email_code', to: "main#regenerate_email_code"
    end
  end
end