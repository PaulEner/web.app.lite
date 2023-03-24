# frozen_string_literal: true
class MyDocuments::AbaseController < FrontController #Must be loaded first that's why there is an "A" in the name
  skip_before_action :login_user!, only: %w[download piece handle_bad_url temp_document get_tag already_exist_document], raise: false
  skip_before_action :verify_if_active, only: %w[export_options export_preseizures download_archive download_bundle get_tags update_tags]

  prepend_view_path('app/templates/front/my_documents/views')

  def export_options
    if params[:type] == 'piece'
      obj = Pack::Piece.where(id: Array(params[:ids])).first
    elsif params[:type] == 'preseizure'
      obj = Pack::Report::Preseizure.where(id: Array(params[:ids])).first
    elsif params[:type] == 'pack'
      obj = Pack.where(id: Array(params[:ids])).first
    elsif params[:type] == 'report'
      obj = Pack::Report.where(id: Array(params[:ids])).first
    end

    user    = obj.try(:user) || obj.try(:owner)
    options = []

    if user
      options << %w[CSV csv] if user.uses?(:csv_descriptor)
      if current_user.is_admin && user.organization.ibiza.try(:configured?) && user.uses?(:ibiza)
        options << ['XML (Ibiza)', 'xml_ibiza']
      end
      options << ['TXT (Ciel)', 'txt_ciel']                    if user.uses?(:ciel)
      options << ['TXT (Quadratus)', 'txt_quadratus']          if user.uses?(:quadratus)
      options << ['ZIP (Quadratus)', 'zip_quadratus']          if user.uses?(:quadratus)
      options << ['ZIP (Coala)', 'zip_coala']                  if user.uses?(:coala)
      options << ['XLS (Coala)', 'xls_coala']                  if user.uses?(:coala)
      options << ['CSV (Cegid)', 'csv_cegid']                  if user.uses?(:cegid)
      options << ['TRA + pièces jointes (Cegid)', 'tra_cegid'] if user.uses?(:cegid)
      options << ['TXT (Fec Agiris)', 'txt_fec_agiris']        if user.uses?(:fec_agiris)
      options << ['TXT (Fec ACD)', 'txt_fec_acd']              if user.uses?(:fec_acd)
      options << ['TXT (Cogilog)', 'txt_cogilog']              if user.uses?(:cogilog)
    end

    options << ['Aucun logiciel comptable paramètré', ''] if options.empty?

    render json: { options: options }, status: 200
  end

  def export_preseizures
    params64 = Base64.decode64(params[:q])
    params64 = JSON.parse(params64)

    export_type = params64['type']
    export_ids  = Array(params64['ids'] || [])
    export_format = params64['format']
    @is_operations = (params64['is_operations'].to_s == 'true')? true : false
    @is_documents  = !@is_operations
    @pluck_preseizures = true

    load_params if export_type == 'pack' || export_type == 'report'

    preseizures = []

    if export_ids.any?
      if export_type == 'piece'
        pieces = Pack::Piece.where(id: export_ids)
        preseizures = pieces.collect(&:preseizures).flatten.compact if pieces.any?
      elsif export_type == 'preseizure'
        preseizures = Pack::Report::Preseizure.where(id: export_ids)
        if preseizures.any?
          @report = preseizures.first.report
          update_report
          preseizures.reload
        end
      elsif export_type == 'pack'
        pack = Pack.where(id: export_ids).first
        reports = pack.present? ? assign_report_with(pack) : []
        if @options[:by_preseizure].present?
          preseizures = Pack::Report::Preseizure.not_deleted.where(report_id: reports.collect(&:id)).where(id: @options[:preseizure_ids])
        else
          preseizures = Pack::Report::Preseizure.not_deleted.where(report_id: reports.collect(&:id))
        end
      elsif export_type == 'report'
        @report = Pack::Report.where(id: export_ids).first
        update_report
        if @options[:by_preseizure].present?
          preseizures = Pack::Report.where(id: export_ids).first.preseizures.where(id: @options[:preseizure_ids])
        else
          preseizures = Pack::Report.where(id: export_ids).first.preseizures
        end
      end
    end

    supported_format = %w[csv xml_ibiza txt_quadratus txt_cogilog zip_quadratus zip_coala xls_coala txt_fec_agiris txt_fec_acd csv_cegid tra_cegid, txt_ciel]

    if preseizures.any? && export_format.in?(supported_format)
      preseizures = preseizures.sort_by{|e| e.position }

      export = PreseizureExport::GeneratePreAssignment.new(preseizures, export_format).generate_on_demand
      if export && export.file_name.present? && export.file_path.present?
        contents = File.read(export.file_path.to_s)

        send_data(contents, filename: File.basename(export.file_name.to_s), disposition: 'attachment')
      else
        render plain: 'Aucun résultat'
      end
    elsif !export_format.in?(supported_format)
      render plain: 'Traitement impossible : le format est incorrect.'
    else
      render plain: 'Aucun résultat'
    end
  end

  def download_archive
    pack = Pack.find(params[:id])
    pack = nil unless pack.owner.in?(accounts)

    begin
      if !pack.cloud_archive.attached? || pack.archive_name.gsub('%', '_') != pack.try(:cloud_archive_object).try(:filename)
        pack.save_archive_to_storage #May takes several times
      end

      zip_path = pack.cloud_archive_object.reload.path.presence || pack.archive_file_path

      ok = pack && File.exist?(zip_path)
    rescue => e
      ok = false
    end

    if ok
      send_file(zip_path, type: 'application/zip', filename: pack.archive_name, x_sendfile: true)
    else
      render plain: "File unavalaible"
    end
  end

  def download_bundle
    @pack = Pack.find params[:id]
    filepath = @pack.cloud_content_object.path

    if File.exist?(filepath.to_s) && (@pack.owner.in?(accounts) || current_user.try(:is_admin))
      mime_type = 'application/pdf'
      send_file(filepath, type: mime_type, filename: @pack.cloud_content_object.filename, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end

  # GET /account/documents/pieces/download_selected/:pieces_ids
  def download_selected_zip
    pieces_ids = params[:ids].split('_')

    if pieces_ids.size > 20
      render body: 'Votre séléction est au-delà de 20 pièces, veuiller contacter le support si vous voulez télécharger plus de 20 pièces svp !', status: 404
    else
      if Pack::Piece.unscoped.where(id: pieces_ids.first).try(:first).try(:user).in?(accounts) || current_user.try(:is_admin)
        tmp_dir = CustomUtils.mktmpdir('download_selected', nil, false)

        pieces_ids.each do |piece_id|
          piece           = Pack::Piece.unscoped.find(piece_id)
          piece_file_name = DocumentTools.file_name piece.name

          file_path = piece.cloud_content_object.path(params[:style].presence || :original, true)

          if !File.exist?(file_path.to_s) && !piece.cloud_content.attached?
            sleep 1
            piece.try(:recreate_pdf)
            file_path = piece.cloud_content_object.reload.path(params[:style].presence || :original, true)
          end

          FileUtils.cp file_path, "#{tmp_dir}/#{piece_file_name}" if File.exist?(file_path.to_s)
        end

         # Finaly zip the temp
        zip_file_name      = "pieces_#{Time.now.strftime('%Y%m%d_%H%M')}.zip"
        zip_path           = "#{tmp_dir}/#{zip_file_name}"
        Dir.chdir tmp_dir
        POSIX::Spawn.system "zip #{zip_file_name} *"

        FileUtils.delay_for(30.minutes, queue: :high).remove_entry(tmp_dir, true)

        if File.exist?(zip_path.to_s)
          mime_type = 'application/zip'
          send_file(zip_path, type: mime_type, filename: File.basename(zip_path), x_sendfile: true, disposition: 'inline')
        else
          render body: 'Aucun fichier à télécharger', status: 404
        end
      else
        render body: 'Aucun fichier à télécharger', status: 404
      end
    end
  end

  def get_tags
    if params[:type] == 'pack'
      @models = Pack.where(id: params[:id])
    elsif params[:type] == "temp_documents"
      @models = TempDocument.where(id: params[:id])
    else
      @models = Pack::Piece.where(id: params[:id])
    end

    render partial: 'tags'
  end

  def update_tags

    UpdateMultipleTags.execute(params[:user_id] || @user.id, params[:tags], Array(params[:ids]), params[:type])

    render json: {message: 'Tag mis à jours avec succès'}, status: :ok
  end

  def deliver_preseizures
    if @user.has_collaborator_action?
      export_type = params[:type]
      export_ids  = Array(params[:ids] || [])

      @is_operations = (params[:is_operations].to_s == 'true')? true : false
      @is_documents  = !@is_operations
      @pluck_preseizures = true

      load_params if export_type == 'pack' || export_type == 'report'

      preseizures = []
      if export_ids.any?
        if export_type == 'piece'
          pieces = Pack::Piece.where(id: export_ids)
          preseizures = pieces.collect(&:preseizures).flatten.compact if pieces.any?
        elsif export_type == 'preseizure'
          preseizures = Pack::Report::Preseizure.where(id: export_ids)
        elsif export_type == 'pack'
          pack = Pack.where(id: export_ids).first
          reports = pack.present? ? assign_report_with(pack) : []
          if @options[:by_preseizure].present?
            preseizures = Pack::Report::Preseizure.not_deleted.where(report_id: reports.collect(&:id)).where(id: @options[:preseizure_ids])
          else
            preseizures = Pack::Report::Preseizure.not_deleted.where(report_id: reports.collect(&:id))
          end
        elsif export_type == 'report'
          if @options[:by_preseizure].present?
            preseizures = Pack::Report.where(id: export_ids).first.preseizures.where(id: @options[:preseizure_ids])
          else
            preseizures = Pack::Report.where(id: export_ids).first.preseizures
          end
        end
      end


      preseizures = preseizures.select{ |preseizure| preseizure.need_delivery? }

      if preseizures.any?
        preseizures.group_by(&:report_id).each do |_report_id, preseizures_by_report|
          PreAssignment::CreateDelivery.new(preseizures_by_report, %w[ibiza exact_online my_unisoft sage_gec acd]).execute
        end
      end

      render json: { success: true, size: preseizures.try(:size).to_i }, status: 200
    else
      render json: { success: true, size: 0 }, status: 200
    end
  end

  def already_exist_document
    @already_document = Archive::AlreadyExist.where(id: params[:id]).first
    render partial: 'already_exist_document'
  end


  # GET /account/documents/exist_document/:id/download
  def exist_document
    auth_token = params[:token]
    auth_token ||= request.original_url.partition('token=').last

    already_doc = Archive::AlreadyExist.find(params[:id])
    filepath    = already_doc.path

    if File.exist?(filepath.to_s) && auth_token == already_doc.get_token
      mime_type = File.extname(filepath) == '.png' ? 'image/png' : 'application/pdf'
      # send_file(filepath, type: mime_type, filename: "document_already_exist.pdf", x_sendfile: true, disposition: 'inline')
      send_data File.read(filepath), filename: "document_already_exist.pdf", type: mime_type, disposition: 'inline' ## TODO: Find why send file doesn't work here
    else
      render body: nil, status: 404
    end
  end

  # GET /contents/original/missing.png
  def handle_bad_url
    token = request.original_url.partition('token=').last

    @piece = Pack::Piece.where('created_at >= ?', '2019-12-28 00:00:00').where('created_at <= ?', '2019-12-31 23:59:59').find_by_token(token)
    filepath = @piece.cloud_content_object.path(:original)

    if File.exist?(filepath)
      mime_type = File.extname(filepath) == '.png' ? 'image/png' : 'application/pdf'

      send_file(filepath, type: mime_type, filename: @piece.cloud_content_object.filename, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end


###################################################################################################
  def multi_pack_download
    CustomUtils.add_chmod_access_into("/nfs/tmp/")
    _tmp_archive = Tempfile.new(['archive', '.zip'], '/nfs/tmp/')
    _tmp_archive_path = _tmp_archive.path
    _tmp_archive.close
    _tmp_archive.unlink

    params_valid = params[:pack_ids].present?
    ready_to_send = false

    if params_valid
      packs = Pack.where(id: params[:pack_ids].split('_')).order(created_at: :desc)

      files_path = packs.map do |pack|
        document = pack.original_document
        if document && (pack.owner.in?(accounts) || curent_user.try(:is_admin))
          document.cloud_content_object.path
        end
      end
      files_path.compact!

      files_path.in_groups_of(50).each do |group|
        DocumentTools.archive(_tmp_archive_path, group)
      end

      ready_to_send = true if files_path.any? && File.exist?(_tmp_archive_path)
    end

    if ready_to_send
      begin
        contents = File.read(_tmp_archive_path)
        File.unlink _tmp_archive_path if File.exist?(_tmp_archive_path)

        send_data(contents, type: 'application/zip', filename: 'pack_archive.zip', disposition: 'attachment')
      rescue StandardError
        File.unlink _tmp_archive_path if File.exist?(_tmp_archive_path)
        redirect_to account_path, alert: 'Impossible de proceder au téléchargment'
      end
    else
      File.unlink _tmp_archive_path if File.exist?(_tmp_archive_path)
      redirect_to account_path, alert: 'Impossible de proceder au téléchargment'
    end
  end

  # POST /account/documents/sync_with_external_file_storage
  def sync_with_external_file_storage
    if current_user.is_admin
      @packs = params[:pack_ids].present? ? Pack.where(id: params[:pack_ids]) : all_packs
      @packs = @packs.order(created_at: :desc)

      type = params[:type].to_i || FileDelivery::RemoteFile::ALL

      @packs.each do |pack|
        FileDelivery.prepare(pack, users: [@user], type: type, force: true, delay: true)
      end
    end

    respond_to do |format|
      format.html { render body: nil, status: 200 }
      format.json { render json: true, status: :ok }
    end
  end

  # GET /account/documents/processing/:id/download/:style
  def download_processing
    document = TempDocument.find(params[:id])
    owner    = document.temp_pack.user
    filepath = document.cloud_content_object.path(params[:style].presence)

    if File.exist?(filepath) && (owner.in?(accounts) || current_user.try(:is_admin))
      mime_type = File.extname(filepath) == '.png' ? 'image/png' : 'application/pdf'
      send_file(filepath, type: mime_type, filename: document.cloud_content_object.filename, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end

  # GET /account/documents/pieces/download_selected/:pieces_ids
  def download_selected
    pieces_ids   = params[:pieces_ids].split('_')
    merged_paths = []
    pieces       = []

    pieces_ids.each do |piece_id|
      piece = Pack::Piece.unscoped.find(piece_id)
      file_path = piece.cloud_content_object.path(params[:style].presence || :original)

      if !File.exist?(file_path.to_s) && !piece.cloud_content.attached?
        sleep 1
        piece.try(:recreate_pdf)
        file_path = piece.cloud_content_object.reload.path(params[:style].presence || :original)
      end

      merged_paths << file_path
      pieces << piece
    end

    if pieces.last.user.in?(accounts) || current_user.try(:is_admin)
      tmp_dir      = CustomUtils.mktmpdir('download_selected', nil, false)
      file_path    = File.join(tmp_dir, "#{pieces_ids.size}_selected_pieces.pdf")

      if merged_paths.size > 1
        is_merged = Pdftk.new.merge merged_paths, file_path
      else
        is_merged = true
        FileUtils.cp merged_paths.first, file_path
      end

      if is_merged && File.exist?(file_path.to_s)
        mime_type = File.extname(file_path) == '.png' ? 'image/png' : 'application/pdf'
        send_file(file_path, type: mime_type, filename: File.basename(file_path), x_sendfile: true, disposition: 'inline')
      else
        render body: nil, status: 404
      end
    else
      render body: nil, status: 404
    end
  end

  # GET /account/documents/temp_documents/:id/download
  def temp_document
    auth_token = params[:token]
    auth_token ||= request.original_url.partition('token=').last

    @temp_document = TempDocument.find(params[:id])
    filepath = @temp_document.cloud_content_object.reload.path(params[:style].presence || :original)

    if File.exist?(filepath.to_s) && (@temp_document.user.in?(accounts) || current_user.try(:is_admin) || auth_token == @temp_document.get_token)
      mime_type = File.extname(filepath) == '.png' ? 'image/png' : 'application/pdf'
      send_file(filepath, type: mime_type, filename: @temp_document.cloud_content_object.filename, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end

  private

  def update_multiple_preseizures_params
    {
      date: params[:preseizures_attributes][:date].presence,
      deadline_date: params[:preseizures_attributes][:deadline_date].presence,
      third_party: params[:preseizures_attributes][:third_party].presence,
      currency: params[:preseizures_attributes][:currency].presence,
      conversion_rate: params[:preseizures_attributes][:conversion_rate].presence,
      observation: params[:preseizures_attributes][:observation].presence
    }.compact
  end

  #####################

  def assign_report_with(pack)
    reports = Pack::Report.where(name: pack.name.gsub('all', '').strip)
    if reports.any?
      reports.each do |report|
        report.update(pack_id: pack.id) if report.pack_id.nil? && report.preseizures.first.try(:piece_id).present?
      end

      reports.reload
    end

    reports
  end

  def update_report
    if @report && @report.name
      pack = Pack.where(name: @report.name + ' all').first
      assign_report_with(pack) if pack.present?
    end
  end

  def load_params
    session_version = 001 #IMPORTANT: CHANGE THE SESSION VERSION IF SESSION STRUCTURE HAS BEEN CHANGED
    session_name    = @is_operations ? 'params_my_documents_operation' : 'params_my_documents_piece'

    if params[:activate_filter] || params[:reinit]
      @s_params = params.permit!.to_h
    elsif params[:_ext]
      @s_params = JSON.parse(Base64.decode64(params[:k]))
    else
      @s_params = (session[session_name.to_sym].present? && session[session_name.to_sym].try(:[], :version) == session_version)? session[session_name.to_sym][:datas] : params.permit!.to_h
    end

    @s_params = @s_params.with_indifferent_access

    @s_params[:by_all]        = @s_params[:by_all].dup.reject{|k, v| k == "position_operation" } if @s_params[:by_all].present? && (@s_params[:by_all].try(:[], :position).blank? || @s_params[:by_all].try(:[], :position).split(',').size > 1)
    @s_params[:by_preseizure] = @s_params[:by_preseizure].dup.reject{|k, v| k == "amount_operation" } if @s_params[:by_preseizure].present? && @s_params[:by_preseizure].try(:[], :amount).blank?
    @s_params = deep_compact(@s_params).with_indifferent_access

    @filters = {}

    @filters[:text]          = @s_params[:text]                  if @s_params[:text].present?
    @filters[:by_all]        = @s_params[:by_all]                if @s_params[:by_all].present?
    @filters[:by_piece]      = @s_params[:by_piece]              if @s_params[:by_piece].present?
    @filters[:by_preseizure] = @s_params[:by_preseizure]         if @s_params[:by_preseizure].present?
    @filters[:journal]       = @s_params[:journal]               if @s_params[:journal].present?
    @filters[:period]        = @s_params[:period]                if @s_params[:period].present?
    @filters[:view]          = ((@s_params[:view].try(:split, ',').try(:size).to_i >= 15) ? nil : @s_params[:view]) if @s_params[:view].present?

    if params[:reinit].present?
      session.delete(session_name.to_sym)
    else
      session[session_name.to_sym] = { version: session_version, datas: @filters }
    end

    load_options
  end

  def load_options
    per_page = @is_operations ? 14 : 40 #IMPORTANT: per_page option (for documents) must be a multiple of 4 and > 8 (needed by grid type view)
    @options = { page: params[:page], per_page: per_page }

    @options[:sort] = true
    @options[:text] = @s_params[:text]

    if @s_params[:by_all].present?
      @s_params[:by_piece] = @s_params[:by_piece].present? ? (@s_params[:by_all].respond_to?(:permit) ? @s_params[:by_piece].merge(@s_params[:by_all].permit!) : @s_params[:by_piece].merge(@s_params[:by_all])) : @s_params[:by_all]
    end

    if @is_documents
      @options[:piece_created_at]           = @s_params[:by_piece].try(:[], :created_at)
      @options[:piece_created_at_operation] = @s_params[:by_piece].try(:[], :created_at_operation)

      @options[:tags] = params[:by_all].try(:[], :tags)

      @options[:pre_assignment_state] = @s_params[:by_piece].try(:[], :state_piece)
      @options[:piece_number]         = @s_params[:by_piece].try(:[], :piece_number)
    end

    position = @s_params[:by_piece].try(:[], :position).try(:split, ',')
    @options[:position]           = position.presence ? position.map{ |pos| pos.strip } : nil
    @options[:position_operation] = @s_params[:by_piece].try(:[], :position_operation)

    @options[:by_preseizure] = @s_params[:by_preseizure]

    @options[:user_ids] = if (@s_params[:view].present? && @s_params[:view] != 'all')
                            @s_params[:view].try(:split, ',') || @s_params[:view] || account_ids
                          else
                            account_ids
                          end

    @options[:user_ids]  = @options[:user_ids].presence || [-1]
    @options[:owner_ids] = @options[:user_ids]

    @options[:journal] =  if @s_params[:journal].present?
                            @s_params[:journal].try(:split, ',') || []
                          else
                            []
                          end

    @options[:period] =   if @s_params[:period].present?
                            @s_params[:period].try(:split, ',') || []
                          else
                            []
                          end

    if @options[:by_preseizure].present?
      if @is_operations
        source  = Pack::Report::Preseizure.where(user_id: @options[:user_ids]).where('operation_id > 0').filter_by(@options[:by_preseizure]).distinct
        if @pluck_preseizures
          preseizure_ids = source.pluck(:id).presence || [0]
        else
          reports_ids = source.pluck(:report_id).presence || [0]
        end
      else
        source  = Pack::Report::Preseizure.where(user_id: @options[:owner_ids]).where('piece_id > 0').filter_by(@options[:by_preseizure]).distinct
        if @pluck_preseizures
          preseizure_ids = source.pluck(:id).presence || [0]
        else
          piece_ids   = source.pluck(:piece_id).presence || [0]
        end
      end
    end

    @options[:ids]            = reports_ids       if reports_ids.present?
    @options[:piece_ids]      = piece_ids         if piece_ids.present?
    @options[:preseizure_ids] = preseizure_ids    if preseizure_ids.present?

    @options
  end


  def deep_compact(hsh)
    res_hash = hsh.map do |key, value|
      value = deep_compact(value) if value.is_a?(Hash)

      value = nil if not value.present?
      [key, value]
    end

    res_hash.to_h.compact
  end

end