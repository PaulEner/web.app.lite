require 'sidekiq/web'
require 'sidekiq-scheduler/web'

class ActionDispatch::Routing::Mapper
  def front_draw(template)
    instance_eval(File.read(Rails.root.join("app/templates/front/#{template}/routes.rb")))
  end

  def back_draw(template)
    instance_eval(File.read(Rails.root.join("app/templates/back/#{template}/routes.rb")))
  end
end

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  mount Ckeditor::Engine => '/ckeditor'

  root :to => redirect('/dashboard')
  get '/front/notifications/', controller: 'front/index', action: 'notifications'

  wash_out :dematbox

  devise_for :users

  authenticate :user, lambda { |u| u.is_admin } do
    mount Sidekiq::Web => '/sidekiq'
  end

  ### ------------------------ front ---------------------------- ###
  get '/', to: redirect('/dashboard')
  front_draw('dashboard')
  front_draw('documentations')
  front_draw('notifications')
  front_draw('news')
  front_draw('account_number_rules')
  front_draw('account_sharings')
  front_draw('addresses')
  front_draw('bank_accounts')
  front_draw('bank_settings')
  front_draw('profiles')
  front_draw('collaborators')
  front_draw('compta_analytics')
  front_draw('exercises')
  front_draw('setups')
  front_draw('orders')
  front_draw('file_naming_policies')
  front_draw('knowings')
  front_draw('invoices')
  front_draw('reminder_emails')
  front_draw('file_sending_kits')
  front_draw('groups')
  front_draw('paper_set_orders')
  front_draw('journals')
  front_draw('ibiza')
  front_draw('my_company_files')
  front_draw('pack_reports')
  front_draw('accounting_plans')
  front_draw('vat_accounts')
  front_draw('csv_descriptors')
  front_draw('subscriptions')
  front_draw('group_organizations')
  front_draw('organizations')
  front_draw('preseizures')
  front_draw('documents')
  front_draw('documents_reloaded')
  front_draw('my_documents')
  front_draw('pieces_errors')
  front_draw('organizations')
  front_draw('reporting')
  front_draw('customers')
  front_draw('periods')
  front_draw('boxes')
  front_draw('external_file_storages')
  front_draw('ftps_setting')
  front_draw('payments')
  front_draw('compositions')
  front_draw('dematboxes')
  front_draw('retrievers')
  front_draw('retrieved_datas')
  front_draw('retrieved_datas_v2')
  front_draw('retriever_parameters')
  front_draw('exact_online')
  front_draw('paper_processes')
  front_draw('suspended')
  front_draw('profiles')
  front_draw('software_setting')

  ### --------------------------- admin ---------------------------- ###

  get 'admin/', to: redirect('/admin/dashboard')
  back_draw('dashboard')
  back_draw('reporting')
  back_draw('organizations')
  back_draw('process_reporting')
  back_draw('invoices')
  back_draw('users')
  back_draw('subscription_options')
  back_draw('subscriptions')
  back_draw('mobile_reporting')
  back_draw('orders')
  back_draw('events')
  back_draw('retrievers')
  back_draw('pre_assignment_deliveries')
  back_draw('dematboxes')
  back_draw('news')
  back_draw('emailed_documents')
  back_draw('cms_images')
  back_draw('scanning_providers')
  back_draw('account_sharings')
  back_draw('notifications')
  back_draw('pre_assignment_blocked_duplicates')
  back_draw('notification_settings')
  back_draw('job_processing')
  back_draw('counter_error_script_mailer')
  back_draw('budgea_retriever')
  back_draw('zoho_crms')
  back_draw('pkill')
  back_draw('reset')
  back_draw('package_setting')
  back_draw('tickets')
  back_draw('supports')

  #### -------------------------------- native resources -----------------------------###

  scope module: 'ppp' do
    resources :compta

    resources :kits, only: %w(index create)
    get 'kits/:year/:month/:day', controller: 'kits', action: 'index', constraints: { year: /\d{4}/, month: /\d{1,2}/, day: /\d{1,2}/ }


    resources :receipts, only: %w(index create)
    get 'receipts/:year/:month/:day', controller: 'receipts', action: 'index', constraints: { year: /\d{4}/, month: /\d{1,2}/, day: /\d{1,2}/ }


    resources :scans, only: %w(index create) do
      patch :add,       on: :member
      get   :cancel,    on: :collection
      patch :overwrite, on: :member
    end
    get 'scans/:year/:month/:day', controller: 'scans', action: 'index', constraints: { year: /\d{4}/, month: /\d{1,2}/, day: /\d{1,2}/ }


    resources :returns, only: %w(index create)
    get 'returns/:year/:month/:day', controller: 'returns', action: 'index', constraints: { year: /\d{4}/, month: /\d{1,2}/, day: /\d{1,2}/ }


    scope '/scans' do
      resource :return_labels
    end
    post '/scans/return_labels/:year/:month/:day',     controller: 'return_labels', action: 'create'
    get  '/scans/return_labels/new/:year/:month/:day', controller: 'return_labels', action: 'new'

    get '/paper_set_orders', controller: 'paper_set_orders', action: 'index'
  end

  namespace :api, defaults: { format: 'json' } do
    namespace :v3 do
      resources :users, only: %w(index) do
        member do
          resources :ledgers, only: %w(index)
        end
      end

      resources :organizations, only: %w() do
        collection do
          get :current
        end
      end

      resources :inbound_documents, only: %w(create)
    end
    namespace :v2 do
      resources :users, only: %w() do
        collection do
          get :jefacture
        end

        resources :accounting_plans,  only: %w(index)
        resources :account_book_types, only: %w(index)
      end

      resources :pieces,            only: %w(update)

      resources :operations,        only: %w(create) do
        get 'by_iban/:iban', action: 'index_by_iban', on: :collection
        post 'not_processed', action: 'not_processed', on: :collection
      end

      resources :temp_documents,    only: %w(create)

      resources :bank_accounts,     only: %w(index) do
        member do
          get :last_operation
        end
      end

      resources :neatops_specific, only: :create
    end

    namespace :v1 do
      resources :pre_assignments do
        post 'update_comment', on: :collection
      end

      resources :system, only: %w(index) do
        post 'my_customers', on: :collection
        post 'piece_url', on: :collection
      end
    end

    namespace :mobile do
      devise_for :users

      resources :remote_authentication do
        collection do
          post :request_connexion
          post :get_user_parameters
          post :ping
        end
      end

      resources :data_loader do
        collection do
          post :load_customers
          post :load_user_organizations
          post :load_packs
          post :load_documents_processed
          post :load_documents_processing
          post :load_stats
          post :load_preseizures
          post :get_packs
          post :get_reports
          get  :render_image_documents
        end
      end

      resources :preseizures do
        collection do
          post :get_details
          post :deliver
          post :edit_preseizures
          post :edit_account
          post :edit_entry
        end
      end

      resources :operations do
        collection do
          post :get_operations
          post :force_pre_assignment
          post :get_customers_options
        end
      end

      resources :account_sharing do
        collection do
          post :load_shared_docs
          post :load_shared_contacts

          post :get_list_collaborators
          post :get_list_customers
          post :add_shared_docs
          post :add_shared_contacts
          post :edit_shared_contacts
          post :accept_shared_docs
          post :delete_shared_docs
          post :delete_shared_contacts

          post :load_shared_docs_customers
          post :add_shared_docs_customers
          post :add_sharing_request_customers
        end
      end

      resources :file_uploader do
        post 'load_file_upload_params', on: :collection
        post 'load_file_upload_users', on: :collection
        post 'load_user_analytics', on: :collection
        post 'set_pieces_analytics', on: :collection
      end

      resources :firebase_notification do
        collection do
          post :get_notifications
          post :release_new_notifications
          post :register_firebase_token
        end
      end

      resources :error_report do
        post 'send_error_report', on: :collection
      end
    end

    namespace :sgi do
      namespace :v1 do
        resources :grouping do
          get 'bundle_needed/:delivery_type', action: 'bundle_needed',  on: :collection
          post 'bundled', on: :collection
        end

        resources :preassignment do
          get 'preassignment_needed/:compta_type', action: 'preassignment_needed', on: :collection
          get 'download_piece', on: :collection
          post 'push_preassignment/:piece_id', action: 'push_preassignment', on: :collection
          post 'update_teeo_pieces', action: 'update_teeo_pieces', on: :collection
        end

        resources :mapping_generator do
          get 'get_json', on: :collection
        end

        resources :jefacture do
          get 'waiting_validation',  on: :collection
          post 'pre_assigned',       on: :collection
        end
      end
    end
  end

  match '*a', to: 'errors#routing', via: :all
end

