Rails.application.routes.draw do
  scope module: 'documentations' do
    get '/docs/download', to: 'main#download', as: 'download_document'
  end
end