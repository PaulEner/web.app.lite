Rails.application.routes.draw do
  scope module: 'retriever_parameters' do
    get '/retriever/parameters', to: 'main#index', as: 'retriever_parameters'

    post '/retriever/integrate_documents', to: 'documents_selection#integrate', as: 'retriever_integrate_documents'
    post '/retriever/bank_activation', to: 'banks_params#bank_activation', as: 'retriever_bank_activation'

    get '/retriever/bank/:id', to: 'banks_params#edit', as: 'retriever_bank_edit'
    get '/retriever/new/bank', to: 'banks_params#new', as: 'retriever_new_bank'
    get '/retriever/bank/:id/download_cedricom_mandate', to: 'banks_params#download_cedricom_mandate', as: 'retriever_download_cedricom_mandate'
    get '/retriever/bank/:id/create_cedricom_mandate', to: 'banks_params#create_cedricom_mandate', as: 'retriever_create_cedricom_mandate'
    patch '/retriever/bank/:id', to: 'banks_params#update', as: 'retriever_bank_update'
    patch '/retriever/new/bank', to: 'banks_params#create', as: 'retriever_create_bank'

    get '/retriever/banks_selection', to: 'banks_selection#index', as: 'retriever_banks_selection'
    get '/retriever/documents_selection', to: 'documents_selection#index', as: 'retriever_documents_selection'
    get '/retriever/banks_params', to: 'banks_params#index', as: 'retriever_banks_params'
  end
end