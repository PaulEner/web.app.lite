Rails.application.routes.draw do
  scope module: 'retrieved_datas' do
    get '/retriever/historics', to: 'main#index', as: 'retrievers_historics'
  end

  scope module: 'retrieved_datas' do
  	get '/retrieved/documents', to: 'documents#index', as: 'retrieved_documents'
  	get '/retrieved/operations', to: 'operations#index', as: 'retrieved_operations'
    post '/retrieved/force_operations', to: 'operations#force_processing', as: 'retrieved_force_operations'
    post '/retrieved/unlock_operations', to: 'operations#unlock_operations', as: 'retrieved_unlock_operations'
  end
end