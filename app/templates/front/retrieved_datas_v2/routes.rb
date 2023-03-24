Rails.application.routes.draw do
  scope module: 'retrieved_datas_v2' do
    get '/retriever_v2/historics', to: 'main#index', as: 'retrievers_historics_v2'
  end

  scope module: 'retrieved_datas_v2' do
  	get '/retrieved_v2/documents', to: 'documents#index', as: 'retrieved_documents_v2'
  	get '/retrieved_v2/operations', to: 'operations#index', as: 'retrieved_operations_v2'
    post '/retrieved_v2/force_operations', to: 'operations#force_processing', as: 'retrieved_force_operations_v2'
    post '/retrieved_v2/unlock_operations', to: 'operations#unlock_operations', as: 'retrieved_unlock_operations_v2'
  end
end