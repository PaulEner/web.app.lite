# encoding: utf-8
Rails.application.routes.draw do
  namespace :admin do
    namespace :dashboard do
      get '/', to: "main#index", as: "root"

      get '/ocr_needed_temp_packs', to: "main#ocr_needed_temp_packs", as: "ocr_needed_temp_packs"
      get '/bundle_needed_temp_packs', to: "main#bundle_needed_temp_packs", as: "bundle_needed_temp_packs"
      get '/processing_temp_packs', to: "main#processing_temp_packs", as: "processing_temp_packs"
      get '/currently_being_delivered_packs', to: "main#currently_being_delivered_packs", as: "currently_being_delivered_packs"
      get '/failed_packs_delivery', to: "main#failed_packs_delivery", as: "failed_packs_delivery"
      get '/blocked_pre_assignments', to: "main#blocked_pre_assignments", as: "blocked_pre_assignments"
      get '/awaiting_pre_assignments', to: "main#awaiting_pre_assignments", as: "awaiting_pre_assignments"
      get '/reports_delivery', to: "main#reports_delivery", as: "reports_delivery"
      get '/failed_reports_delivery', to: "main#failed_reports_delivery", as: "failed_reports_delivery"
      get '/awaiting_supplier_recognition', to: "main#awaiting_supplier_recognition", as: "awaiting_supplier_recognition"
      get '/awaiting_adr', to: "main#awaiting_adr", as: "awaiting_adr"
      get '/cedricom_orphans', to: "main#cedricom_orphans", as: "cedricom_orphans"
      get '/chart_flux_document', to: "main#chart_flux_document", as: "chart_flux_document"
      get '/document_delivery', to: "main#document_delivery", as: "document_delivery"
      get '/document_api', to: "main#document_api", as: "document_api"
      get '/software_customers', to: "main#software_customers", as: "software_customers"
      get '/bank_operation', to: "main#bank_operation", as: "bank_operation"
    end
  end
end
