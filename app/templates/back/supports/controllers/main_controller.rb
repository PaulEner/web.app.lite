# frozen_string_literal: true
class Admin::Supports::MainController < BackController
  prepend_view_path('app/templates/back/supports/views')

  # GET /admin/supports
  def index; end

  def get_retriever
    @user = User.find_by_code(params[:user_code]) if not params[:user_code].blank?

    if @user
      render partial: "get_retriever"
    else
      render plain: 'Aucun résultat'
    end  	
  end

  def get_bank_accounts
    @retriever = Retriever.find params[:retriever_id]

    if @retriever
      render partial: "get_bank_accounts"
    else
      render plain: 'Aucun résultat'
    end   
  end  

  def get_operations
    params[:sort] = 'date' if !params[:sort].present?

    @operations = params[:ope_bank_number].present? ? BankAccount.find_by_number(params[:ope_bank_number]).operations : Operation.all

    if !params[:ope_user_code].blank?
      user = User.find_by_code(params[:ope_user_code].strip)

      @operations = @operations.where("operations.user_id = #{user.try(:id)}")
    end

    @operations = @operations.where('operations.label LIKE "%' + params[:ope_label] + '%"')                                                if params[:ope_label].present?
    @operations = @operations.where("operations.date BETWEEN '#{CustomUtils.parse_date_range_of(params[:ope_date]).join("' AND '")}'")  if params[:ope_date].present?
    @operations = @operations.where("operations.api_id = #{params[:ope_api_id]}")                    if params[:ope_api_id].present?
    @operations = @operations.where("operations.is_coming = #{params[:is_coming] == 'true'}")        if params[:is_coming].present?
    @operations = @operations.where("operations.is_locked = #{params[:is_locked] == 'true'}")        if params[:is_locked].present?

    if params[:processed_at] == "1"
      @operations = @operations.where.not(processed_at: nil) 
    elsif params[:processed_at] == "0"
      @operations = @operations.where(processed_at: nil)
    end

    if @operations.try(:any?)
      @operations = @operations.joins(:bank_account).where("bank_accounts.is_used = true")
      @operations = @operations.order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])

      if @operations.try(:any?)
        render partial: "get_operations"
      else
        render plain: 'Aucun résultat'
      end
    else
      render plain: 'Aucun résultat'
    end   
  end

  def get_flux_bridge    
    if params[:bridge_code_user].present? && params[:bridge_bank_ids].present? && params[:ope_date].present?
      date       = params[:ope_date].split('-')

      user       = User.find_by_code params[:bridge_code_user]
      start_time = Time.new(date[0],date[1], date[2])

      b_ids      = params[:bridge_bank_ids].present? ? [params[:bridge_bank_ids]] : []
      if user
        begin
          Bridge::GetTransactions.new(user).execute(start_time, b_ids)
        rescue => e
          render plain: e.to_json
        end

        render plain: 'Récupération Flux lancer'
      else
        render plain: "Le client n'existe pas"
      end      
    else
      render plain: 'Paramètre manquant'
    end    
  end

  def get_ba_free
    if params[:bridge_code_user].present?
      user = User.find_by_code params[:bridge_code_user]

      if user
        access_token = Bridge::Authenticate.new(user).execute

        begin
          @accounts    = BridgeBankin::Account.list(access_token: access_token)

          render partial: "get_bridge_accounts"
        rescue => e
          render plain: e.to_json
        end        
      else
        render plain: "Le client n'existe pas"
      end
    else
      render plain: 'Paramètre manquant'
    end    
  end

  def get_transaction_free
    if params[:bridge_code_user].present? && params[:bridge_bank_ids].present? && params[:ope_date].present?
      user = User.find_by_code params[:bridge_code_user]
      date = params[:ope_date].split('-')

      if user        
        access_token = Bridge::Authenticate.new(user).execute
        start_time   = Time.new(date[0],date[1], date[2])

        begin
          bank_account = user.bank_accounts.find params[:bridge_bank_ids]
          @transactions = BridgeBankin::Transaction.list_by_account(account_id: bank_account.api_id, access_token: access_token, since: start_time)


          render partial: "get_transaction_free"
        rescue => e
          render plain: e.to_json
        end
      else
        render plain: "Le client n'existe pas"
      end
    else
      render plain: 'Paramètre manquant'
    end  
  end

  def resume_me
    retriever = Retriever.find params[:retriever_id]

    if retriever
      retriever.resume_me(true)

      render plain: "Resume automate réussi"
    else
      render plain: 'Action avorté'
    end    
  end

  def switch
    user = User.find_by_code(params[:user_code]) if not params[:user_code].blank?

    if user
      bank = (params[:to] == "budgea_to_bridge") ? 'bridge' : 'budget_insight'

      user.options.update_attribute(:default_banking_provider, bank)

      render plain: "#{user.code} basculé vers #{bank.capitalize}"
    else
      render plain: 'Modification non éffectué'
    end    
  end

  def resend_operation
    operations = Operation.where(id: params[:ids]) 

    operations.each do |operation|      
      operation.update(is_locked: false) if not operation.to_lock?     
    end

    render plain: "Modifié avec succès"
  end

  def resend_to_preassignment
    pieces = Pack::Piece.where(id: params[:ids])

    pieces.each do |piece|
      piece.preseizures.destroy_all

      piece.pre_assignment_state = "waiting"
      piece.created_at           = Time.now if piece.created_at < 3.month.ago

      piece.save 
    end

    render plain: "Modifié avec succès"
  end

  def resend_delivery
    preseizures = Pack::Report::Preseizure.where(id: params[:ids])
    preseizures.update_all(is_locked: false)

    if preseizures.any?
      preseizures.group_by(&:report_id).each do |_report_id, preseizures_by_report|
        PreAssignment::CreateDelivery.new(preseizures_by_report, %w[ibiza exact_online my_unisoft sage_gec acd], {force: true}).execute
      end
    end

    render plain: "Livraison de #{preseizures.size} écriture(s) comptable(s) en cours ..."
  end

  def get_pieces
    if params[:pack_piece_name].present?
      @pieces = Pack.find_by_name(params[:pack_piece_name].strip + ' all')&.pieces.presence || []
    else
      @pieces = params[:piece_name].present? ? Pack::Piece.find_by_name(params[:piece_name].strip) : []
    end

    if @pieces.try(:any?)
      @pieces = @pieces.order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])

      render partial: 'get_pieces'
    else
      render plain: 'Aucun résultat'
    end 
  end

  def get_preseizures
    if params[:message_error].present?
      @preseizures = Pack::Report::Preseizure.where('pack_report_preseizures.delivery_message LIKE "%'+ params[:message_error] +'%"')
    elsif params[:preseizure_date].present?
      @preseizures = Pack::Report::Preseizure.where("pack_report_preseizures.date BETWEEN '#{CustomUtils.parse_date_range_of(params[:preseizure_date]).join("' AND '")}'")
    elsif params[:pack_piece_name].present?
      @preseizures = Pack.find_by_name(params[:pack_piece_name].strip + ' all')&.preseizures.presence || []
    else
      @preseizures = params[:piece_name].present? ? Pack::Piece.find_by_name(params[:piece_name].strip)&.preseizures : []
    end

    if @preseizures.try(:any?)
      @preseizures = @preseizures.order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])

      render partial: 'get_preseizures'
    else
      render plain: 'Aucun résultat'
    end 
  end

  def get_temp_document
    if params[:pack_piece_name].present?
      temp_pack = TempPack.find_by_name(params[:pack_piece_name].to_s + ' all')

      if temp_pack
        @temp_documents = temp_pack.temp_documents.order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])

        render partial: "get_temp_document"
      else
        render plain: "Le pack n'existe pas"
      end
    else
      render plain: 'Paramètre manquant'
    end    
  end

  def destroy_temp_document
    temp_documents = TempDocument.where(id: params[:ids]).where(state: ['created','ocr_needed','unreadable','wait_selection'])

    temp_documents.destroy_all if temp_documents.any?

    render plain: "#{temp_documents.size} temp_document(s) supprimé(s)"  
  end

  def delete_fingerprint_temp_document
    temp_documents = TempDocument.where(id: params[:ids])

    if temp_documents
      temp_documents.update(original_fingerprint: "")

      render plain: "fingerprint supprimé"
    else
      render plain: "Temp document n'existe pas"
    end    
  end

  def set_delivery_external
    if params[:code_client].present?
      user = User.get_by_code params[:code_client]

      if user
        remote_files = user.remote_files.not_processed
        remote_files = remote_files.where("remote_files.created_at BETWEEN '#{CustomUtils.parse_date_range_of(params[:external_date]).join("' AND '")}'") if params[:external_date].present?

        remote_files.map(&:waiting!)

        render plain: "Livraison relancer"

      else
        render plain: "Le client n'existe pas"
      end
    else
      render plain: 'Paramètre manquant'
    end  
  end

  def generate_password
    @user = User.find_by_code(params[:code_client]) if not params[:code_client].blank?

    if @user
      new_password   = SecureRandom.hex(10)
      @user.password = new_password

      if @user.save
        render plain: "Nouveau MDP : <b>#{new_password}</b>"
      else
        render plain: "Action avorté : #{@user.errors.messages}"
      end
    else
      render plain: 'Client introuvable'
    end 
  end

  def generate_mail
    organizations = params[:organization_code].blank? ? Organization.all : Organization.where(code: params[:organization_code])
    @datas        = []

    if organizations
      organizations.each do |organization|
        collab_mails    = organization.members.search({role: 'collaborator'}).collect(&:user).pluck(:email).join(',')
        admin_mails     = organization.members.search({role: 'admin'}).collect(&:user).pluck(:email).join(',')
        customers_mails = organization.customers.active_at(Time.now).pluck(:email).join(',')

        @datas << { organization: organization.name, collab_mails: collab_mails, admin_mails: admin_mails, customers_mails: customers_mails }
      end     

      render partial: "organization_mail"
    else
      render plain: 'Organisation introuvable'
    end
  end


  private

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction
end