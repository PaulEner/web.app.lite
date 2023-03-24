# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    resources :job_processing, only: :index, module: 'job_processing', controller: 'main' do
      get 'kill_job_softly', on: :collection
      get 'real_time_event', on: :collection
      get 'launch_data_verif', on: :collection
    end
  end
end
