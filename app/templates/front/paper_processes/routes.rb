Rails.application.routes.draw do
  scope module: 'paper_processes' do
    resources :paper_processes, only: :index, controller: 'main'
  end
end