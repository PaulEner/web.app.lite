# frozen_string_literal: true
class Admin::Dashboard::MainController < BackController
  prepend_view_path('app/templates/back/dashboard/views')

  def index
    @unbillable_organizations = Organization.billed.select { |e| e.billing_address.nil? }
  end

  # GET /admin/ocr_needed_temp_packs
  def ocr_needed_temp_packs
    @ocr_needed_temp_packs = TempDocument.where(state: 'ocr_needed').group(:temp_pack_id).includes(:temp_pack).map do |data|
      object = OpenStruct.new
      object.date           = data.try(:updated_at).try(:localtime)
      object.name           = data.temp_pack.name.sub(/ all\z/, '')
      object.document_count = data.temp_pack.temp_documents.ocr_needed.count
      object.message        = false
      object
    end

    render partial: 'result', locals: { collection: @ocr_needed_temp_packs, header: {1 => 'Date', 2 => 'Nom Lot', 3 => 'Nb. docs.', 4 => 'Origine'}}
  end

  # GET /admin/bundle_needed_temp_packs
  def bundle_needed_temp_packs
    @bundle_needed_temp_packs = TempPack.bundle_needed.map do |temp_pack|
      temp_documents = temp_pack.temp_documents.bundle_needed.by_position
      object = OpenStruct.new
      object.date           = temp_documents.last.try(:updated_at).try(:localtime)
      object.name           = temp_pack.name.sub(/ all\z/, '')
      object.document_count = temp_documents.count
      object.message        = temp_documents.map(&:delivery_type).uniq.join(', ')
      object
    end.sort_by { |o| [o.date ? 0 : 1, o.date] }.reverse

    render partial: 'result', locals: { collection: @bundle_needed_temp_packs, header: {1 => 'Date dernier doc.', 2 => 'Lot', 3 => 'Nb. docs.', 4 => 'Origine'}}    
  end

  # GET /admin/processing_temp_packs
  def processing_temp_packs
    @processing_temp_packs = TempPack.not_processed.map do |temp_pack|
      temp_documents = temp_pack.temp_documents.ready.by_position
      object = OpenStruct.new
      object.date           = temp_documents.last.try(:updated_at).try(:localtime)
      object.name           = temp_pack.name.sub(/ all\z/, '')
      object.document_count = temp_documents.count
      object.message        = temp_documents.map(&:delivery_type).uniq.join(', ')
      object
    end.sort_by { |o| [o.date ? 0 : 1, o.date] }.reverse

    render partial: 'result', locals: { collection: @processing_temp_packs, header: {1 => 'Date dernier doc.', 2 => 'Lot', 3 => 'Nb. docs.', 4 => 'Origine'}}
  end

  # GET /admin/currently_being_delivered_packs
  def currently_being_delivered_packs
    pack_ids = RemoteFile.where("DATE_FORMAT(updated_at, '%Y%m') >= #{15.days.ago.strftime('%Y%m')}").not_processed.retryable.pluck(:pack_id)
    @currently_being_delivered_packs = Pack.where(id: pack_ids).map do |pack|
      Rails.cache.fetch ['pack', pack.id.to_s, 'remote_files', 'retryable', pack.remote_files_updated_at] do
        remote_files = pack.remote_files.not_processed.retryable.order(created_at: :asc)
        data = remote_files.map do |remote_file|
          name = remote_file.user.try(:my_code) || remote_file.group.try(:name) || remote_file.organization.try(:name)
          [name, remote_file.service_name].join(' : ')
        end.uniq

        object = OpenStruct.new
        object.date           = remote_files.last.try(:created_at).try(:localtime)
        object.name           = pack.name.sub(/ all\z/, '')
        object.document_count = remote_files.count
        object.message        = data.join(', ')
        object
      end
    end.sort_by { |o| [o.date ? 0 : 1, o.date] }.reverse

    render partial: 'result', locals: { collection: @currently_being_delivered_packs, header: {1 => 'Date dernier doc.', 2 => 'Lot', 3 => 'Nb. pièces.', 4 => 'Message'}}
  end

  # GET /admin/failed_packs_delivery
  def failed_packs_delivery
    pack_ids = RemoteFile.not_processed.not_retryable.where('created_at >= ?', 15.days.ago).pluck(:pack_id)

    error_messages = []

    @failed_packs_delivery = Pack.where(id: pack_ids).map do |pack|
      Rails.cache.fetch ['pack', pack.id.to_s, 'remote_files', 'not_retryable', pack.remote_files_updated_at] do
        remote_files = pack.remote_files.not_processed.not_retryable.order(created_at: :asc)
        data = remote_files.map do |remote_file|
          name = remote_file.user.try(:my_code) || remote_file.group.try(:name) || remote_file.organization.try(:name)
          error_messages << remote_file.error_message
          [name, remote_file.service_name].join(' : ')
        end.uniq

        object = OpenStruct.new
        object.date           = remote_files.last.try(:created_at).try(:localtime)
        object.name           = pack.name.sub(/ all\z/, '')
        object.document_count = remote_files.count
        object.message        = data.join(', ')
        object.error_message  = error_messages.uniq.join(', ')
        object
      end
    end.sort_by { |o| [o.date ? 0 : 1, o.date] }.reverse

    render partial: 'result', locals: { collection: @failed_packs_delivery, header: {1 => 'Date dernier doc.', 2 => 'Lot', 3 => 'Nb. pièces.', 4 => 'Message'}} 
  end

  # GET /admin/blocked_pre_assignments
  def blocked_pre_assignments
    @blocked_pre_assignments = PreAssignment::Pending.unresolved.select { |e| e.message.present? }

    render partial: 'result', locals: { collection: @blocked_pre_assignments, header: {1 => 'Date dernier doc.', 2 => 'Lot', 3 => 'Nb. pièces.', 4 => 'Message'}} 
  end

  # GET /admin/awaiting_pre_assignments
  def awaiting_pre_assignments
    @awaiting_pre_assignments = PreAssignment::Pending.unresolved.select { |e| (e.message.blank? || e.pre_assignment_state == 'force_processing') }

    render partial: 'result', locals: { collection: @awaiting_pre_assignments, header: {1 => 'Date dernier doc.', 2 => 'Lot', 3 => 'Nb. pièces.', 4 => 'Message'}} 
  end

  # GET /admin/awaiting_supplier_recognition
  def awaiting_supplier_recognition
    @awaiting_supplier_recognition = Pack::Piece.pre_assignment_supplier_recognition.group(:pack_id).group(:pre_assignment_comment).order(created_at: :desc).includes(:pack).map do |e|
        object = OpenStruct.new
        object.date           = e.created_at.try(:localtime)
        object.name           = e.pack.name.sub(/\s\d+\z/, '').sub(' all', '') if e.pack
        object.document_count = Pack::Piece.pre_assignment_supplier_recognition.where(pack_id: e.pack_id).count
        object
    end

    render partial: 'result', locals: { collection: @awaiting_supplier_recognition, header: {1 => 'Date dernier doc.', 2 => 'Lot', 3 => 'Nb. pièces.', 4 => 'Message'}}
  end

  # GET /admin/awaiting_adr
  def awaiting_adr
    @awaiting_adr = Pack::Piece.pre_assignment_adr.group(:pack_id).group(:pre_assignment_comment).order(created_at: :desc).includes(:pack).map do |e|
        object = OpenStruct.new
        object.date           = e.created_at.try(:localtime)
        object.name           = e.pack.name.sub(/\s\d+\z/, '').sub(' all', '') if e.pack
        object.document_count = Pack::Piece.pre_assignment_adr.where(pack_id: e.pack_id).count
        object
    end

    render partial: 'result', locals: { collection: @awaiting_adr, header: {1 => 'Date dernier doc.', 2 => 'Lot', 3 => 'Nb. pièces.', 4 => 'Message'}}
  end

  # GET /admin/reports_delivery
  def reports_delivery
    @reports_delivery = Pack::Report.locked.order(updated_at: :desc).map do |report|
      object = OpenStruct.new
      object.date           = report.updated_at.try(:localtime)
      object.name           = report.name.sub(/ all\z/, '')
      object.document_count = report.preseizures.locked.count
      object.message        = false
      object
    end

    render partial: 'result', locals: { collection: @reports_delivery, header: {1 => 'Date dernier doc.', 2 => 'Lot', 3 => 'Nb. écritures.', 4 => 'Message'}}  
  end

  # GET /admin/failed_reports_delivery
  def failed_reports_delivery
    @failed_reports_delivery = Pack::Report.failed_delivery(nil, 200)

    render partial: 'result', locals: { collection: @failed_reports_delivery, header: {1 => 'Date dernier doc.', 2 => 'Lot', 3 => 'Nb. écritures.', 4 => 'Message'}} 
  end

  # GET /admin/cedricom_orphans
  def cedricom_orphans
    @orphans = Operation.cedricom_orphans.group(:organization_id, :unrecognized_iban).group("DATE(created_at)").count

    render partial: 'result', locals: { collection: @orphans, header: {1 => 'Date import', 2 => 'Organisation', 3 => 'Nb. opérations', 4 => 'Compte', 5 => 'cedricom'}} 
  end

  def chart_flux_document
    data = {}
    data['title'] = 'Traitement des documents'
    data['header'] = ['Corrompus', 'Bloqués', 'En attente de sélection', 'OCR', 'A regrouper', 'Prêt à être intégrés', 'Traités']
    data['info'] = "Nb. Documents"
    data['value'] = %w(unreadable_temp_documents_count locked_temp_documents_count wait_selection_temp_documents_count ocr_needed_temp_documents_count bundle_needed_temp_documents_count ready_temp_documents_count processed_temp_documents_count).map { |doc| StatisticsManager.get_statistic(doc) }
    data['bg_color'] = [
                'rgba(255, 99, 132, 0.2)',
                'rgba(255, 159, 64, 0.2)',
                'rgba(255, 205, 86, 0.2)',
                'rgba(75, 192, 192, 0.2)',
                'rgba(54, 162, 235, 0.2)',
                'rgba(153, 102, 255, 0.2)',
                'rgba(201, 203, 207, 0.2)'
              ]
    data['border_color'] = [
                'rgb(255, 99, 132)',
                'rgb(255, 159, 64)',
                'rgb(255, 205, 86)',
                'rgb(75, 192, 192)',
                'rgb(54, 162, 235)',
                'rgb(153, 102, 255)',
                'rgb(201, 203, 207)'
              ]

    render json: { result: data }, status: 200   
  end
  def document_delivery
    data = {}
    data['x_name'] = ['Dropbox', 'Google Drive', 'Box', 'FTP', 'MCF']
    data['legend_1'] = 'Restant'
    data['legend_2'] = 'Echoué'

    data['value_1'] = %w(not_processed_retryable_dropbox_remote_files_count not_processed_retryable_google_drive_remote_files_count not_processed_retryable_box_remote_files_count not_processed_retryable_ftp_remote_files_count not_processed_retryable_mcf_remote_files_count).map { |doc| StatisticsManager.get_statistic(doc) }

    data['value_2'] = %w(not_processed_not_retryable_dropbox_remote_files_count not_processed_not_retryable_google_drive_remote_files_count not_processed_not_retryable_box_remote_files_count not_processed_not_retryable_ftp_remote_files_count not_processed_not_retryable_mcf_remote_files_count).map { |doc| StatisticsManager.get_statistic(doc) }

    data['border_color_1'] = "rgb(75, 192, 192)"
    data['border_color_2'] = "rgb(255, 159, 64)"

    render json: { result: data }, status: 200    
  end

  def document_api
    data = {}
    data['title'] = 'Documents téléversés par api'
    data['header'] = ['Aucun', 'budgea', 'ibiza', 'web', 'email', 'dropbox', 'ftp', 'mcf', 'mobile', 'scan', 'invoice setting', 'jefacture', 'sftp']
    data['info'] = "Nb. Documents"
    data['value'] = %w(aucun_temp_documents_count budgea_temp_documents_count ibiza_temp_documents_count web_temp_documents_count email_temp_documents_count dropbox_temp_documents_count ftp_temp_documents_count mcf_temp_documents_count mobile_temp_documents_count scan_temp_documents_count invoice_setting_temp_documents_count jefacture_temp_documents_count sftp_temp_documents_count).map { |doc| StatisticsManager.get_statistic(doc) }

    data['value'] = [12, 32, 45, 17, 96, 23, 12, 54, 47, 58, 36, 86, 15] if Rails.env == 'development'

    data['bg_color'] = [
                'rgba(255, 99, 132, 0.2)',
                'rgba(255, 205, 86, 0.2)',
                'rgba(75, 192, 192, 0.2)',
                'rgba(54, 162, 235, 0.2)',
                'rgba(153, 102, 255, 0.2)',
                'rgba(80, 200, 39, 0.2)',
                'rgba(145, 123, 75, 0.2)',
                'rgba(23, 45, 26, 0.2)',
                'rgba(36, 75, 139, 0.2)',
                'rgba(126, 36, 128, 0.2)',
                'rgba(53, 75, 250, 0.2)',
                'rgba(93, 95, 255, 0.2)',
                'rgba(56, 34, 128, 0.2)'
              ]
    data['border_color'] = [
                'rgba(255, 99, 132)',
                'rgba(255, 205, 86)',
                'rgba(75, 192, 192)',
                'rgba(54, 162, 235)',
                'rgba(153, 102, 255)',
                'rgba(80, 200, 39)',
                'rgba(145, 123, 75)',
                'rgba(23, 45, 26)',
                'rgba(85, 56, 198)',
                'rgba(126, 36, 128)',
                'rgba(53, 75, 250)',
                'rgba(93, 95, 255)',
                'rgba(56, 34, 128)'
              ]    
    render json: { result: data }, status: 200    
  end

  def bank_operation
    data = {}
    data['x_name'] = ['Traités', 'En attente', 'Bloqués']
    data['legend_1'] = 'Budgea'
    data['legend_2'] = 'Bridge'
    data['legend_3'] = 'Manuel'

    data['value_1'] = %w(budgea_processed_operations_count budgea_not_processed_not_locked_operations_count budgea_not_processed_locked_operations_count).map { |doc| StatisticsManager.get_statistic(doc) }

    data['value_2'] = %w(bridge_processed_operations_count bridge_not_processed_not_locked_operations_count bridge_not_processed_locked_operations_count).map { |doc| StatisticsManager.get_statistic(doc) }

    data['value_3'] = %w(capidocus_processed_operations_count capidocus_not_processed_not_locked_operations_count capidocus_not_processed_locked_operations_count).map { |doc| StatisticsManager.get_statistic(doc) }

    if Rails.env == 'development'
      data['value_1'] = [54, 32, 45, 17, 96, 23, 12]
      data['value_2'] = [54, 47, 16, 58, 36, 86, 15]
      data['value_3'] = [54, 16, 58, 36, 47, 86, 15]
    end

    data['border_color_1'] = "rgb(75, 21, 192)"
    data['border_color_2'] = "rgb(255, 85, 64)"
    data['border_color_3'] = "rgb(26, 85, 64)"

    render json: { result: data }, status: 200
  end

  def software_customers
    data = {}
    data['x_name'] = ['iBiza', 'Coala', 'Quadratus', 'Cegid', 'Fec Agiris', 'Autre(format d\'export .csv)']
    data['legend_1'] = 'Organisation'
    data['legend_2'] = 'Client'

    data['value_1'] = %w(ibiza_organizations_count coalaorganizations_count quadratus_organizations_count cegid_organizations_count fec_agirisorganizations_count csv_descriptor_organizations_count).map { |doc| StatisticsManager.get_statistic(doc) }

    data['value_2'] = %w(ibiza_users_count coala_users_count quadratus_users_count cegid_users_count fec_agiris_users_count csv_descriptor_users_count).map { |doc| StatisticsManager.get_statistic(doc) }

    if Rails.env == 'development'
      data['value_1'] = [12, 45, 17, 96, 23, 12]
      data['value_2'] = [22, 16, 58, 36, 86, 15]
    end

    data['border_color_1'] = "rgb(75, 21, 192)"
    data['border_color_2'] = "rgb(255, 85, 64)"

    render json: { result: data }, status: 200
  end
end