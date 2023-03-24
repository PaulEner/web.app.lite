# frozen_string_literal: true
class AccountingPlans::MainController < CustomerController
  before_action :load_customer
  before_action :verify_rights
  before_action :verify_if_customer_is_active
  before_action :load_accounting_plan

  prepend_view_path('app/templates/front/accounting_plans/views')


  # GET /organizations/:organization_id/customers/:customer_id/accounting_plan
  def show
    if params[:dir].present?
      FileUtils.rm_rf params[:dir] if params[:dir]

      redirect_to organization_customer_accounting_plan_path(@organization, @customer)
    end
  end

  # GET /organizations/:organization_id/customers/:customer_id/accounting_plan/edit
  def edit
    if params[:type] == 'provider'
      @accounting_plan_item = @accounting_plan.providers.find(params[:accounting_id])
      @conterpart_accounts  = @accounting_plan.conterpart_accounts.provider.order(:name).map{|account| ["#{account.name} - #{account.number}", account.id] }
    else
      @accounting_plan_item = @accounting_plan.customers.find(params[:accounting_id])
      @conterpart_accounts  = @accounting_plan.conterpart_accounts.customer.order(:name).map{|account| ["#{account.name} - #{account.number}", account.id] }
    end

    render partial: 'edit'
  end

  # PUT /organizations/:organization_id/customers/:customer_id/accounting_plan/:id
  def update
    accounting_plan_item = params[:accounting_plan_item][:type] == 'provider' ? @accounting_plan.providers.find(params[:accounting_plan_item][:id]) : @accounting_plan.customers.find(params[:accounting_plan_item][:id])

    accounting_plan_item.assign_attributes items_params

    if accounting_plan_item.save
      update_conterpart_accounts(accounting_plan_item)

      json_flash[:success] = 'Modifié avec succès.'
    else
      json_flash[:error] = errors_to_list accounting_plan_item
    end

    render json: { json_flash: json_flash, url: organization_customer_accounting_plan_path(@organization, @customer, { tab: params[:accounting_plan_item][:type]}) }, status: 200   
  end

  # POST /organizations/:organization_id/customers/:customer_id/accounting_plan/:id
  def create
    accounting_plan_item = AccountingPlanItem.new

    accounting_plan_item.assign_attributes items_params

    accounting_plan_item.accounting_plan_itemable_id   = @accounting_plan.id
    accounting_plan_item.accounting_plan_itemable_type = "AccountingPlan"

    accounting_plan_item.kind = params[:accounting_plan_item][:type]

    accounting_plan_item.is_updated = true
    
    if accounting_plan_item.save
      update_conterpart_accounts(accounting_plan_item)

      json_flash[:success] = 'Ajouté avec succès.'
    else
      json_flash[:error] = errors_to_list accounting_plan_item
    end

    render json: { json_flash: json_flash, url: organization_customer_accounting_plan_path(@organization, @customer, { tab: params[:accounting_plan_item][:type]}) }, status: 200
  end

  def new
    @accounting_plan_item = AccountingPlanItem.new

    if params[:type] == 'provider'
      @conterpart_accounts  = @accounting_plan.conterpart_accounts.provider.order(:name).map{|account| ["#{account.name} - #{account.number}", account.id] }
    else
      @conterpart_accounts  = @accounting_plan.conterpart_accounts.customer.order(:name).map{|account| ["#{account.name} - #{account.number}", account.id] }
    end
    
    render partial: 'edit'
  end

  def destroy
    accounting_plan_item = params[:type] == 'provider' ? @accounting_plan.providers.find(params[:_id]) : @accounting_plan.customers.find(params[:_id])

    accounting_plan_item.destroy

    label_delete = params[:type] == 'provider' ? 'Fournisseur ' : 'Client'

    flash[:success] = label_delete + ' supprimés avec succès.'

    redirect_to organization_customer_accounting_plan_path(@organization, @customer, { tab: params[:type]})
  end

  # POST /organizations/:organization_id/customers/:customer_id/accounting_plan/ibiza_auto_update
  def auto_update
    if params[:software].present? && params[:software_table].present?
      @customer.try(params[:software_table].to_sym).update(is_auto_updating_accounting_plan: auto_update_accounting_plan_active?)

      if @customer.save
        if @customer.try(params[:software_table].to_sym).try(:auto_update_accounting_plan?)
          AccountingPlan::SageGecUpdate.new(@customer).run if params[:software_table] == 'sage_gec'

          render json: { success: true, message: "La mis à jour automatique du plan comptable chez #{params[:software]} est activé" }, status: 200
        else
          render json: { success: true, message: "La mis à jour automatique du plan comptable chez #{params[:software]} est désactivé" }, status: 200
        end
      else
        render json: { success: false, message: "Impossible d\'activer/désactiver le mis à jour automatique du plan comptable chez #{params[:software]}" }, status: 200
      end
    end
  end

  # POST /organizations/:organization_id/customers/:customer_id/accounting_plan/ibiza_synchronize
  def ibiza_synchronize
    # TODO ... Import accounting plan into iBiza inverse of upadte accounting plan service
  end

  # GET /organizations/:organization_id/customers/:customer_id/accounting_plan/import_model
  def import_model
    data = "NOM_TIERS;COMPTE_TIERS;COMPTE_CONTREPARTIE;CODE_TVA\n"

    send_data(data, type: 'plain/text', filename: "modèle d'import.csv")
  end

  # PUT /organizations/:organization_id/customers/:customer_id/accounting_plan/import
  def import
    if params[:providers_file]
      file = params[:providers_file]
      type = 'providers'
    elsif params[:customers_file]
      file = params[:customers_file]
      type = 'customers'
    end

    if file
      if @accounting_plan.import(file, type)
        flash[:success] = 'Importé avec succès.'
      else
        flash[:error] = 'Fichier non valide.'
      end
    else
      flash[:error] = 'Aucun fichier choisi.'
    end
    
    redirect_to organization_customer_accounting_plan_path(@organization, @customer)
  end

  def import_fec
    if params[:fec_file].present?
      original_file = params[:fec_file].path

      unless DocumentTools.is_utf8(original_file)
        flash[:error] = 'Format de fichier non supporté. (UTF-8 sans bom recommandé)'
      else
        return false if params[:fec_file].content_type != "text/plain"

        @dir = CustomUtils.mktmpdir('fec_import', "/nfs/import/FEC/", false)

        @file   = File.join(@dir, "file_#{Time.now.strftime('%Y%m%d%H%M%S')}.txt")
        journal = []

        txt_file = File.read(original_file)
        txt_file.encode!('UTF-8')

        begin
          txt_file.force_encoding('ISO-8859-1').encode!('UTF-8', undef: :replace, invalid: :replace, replace: '') if txt_file.match(/\\x([0-9a-zA-Z]{2})/)
        rescue => e
          txt_file.force_encoding('ISO-8859-1').encode!('UTF-8', undef: :replace, invalid: :replace, replace: '')
        end

        begin
          txt_file.gsub!("\xEF\xBB\xBF".force_encoding("UTF-8"), '') #deletion of UTF-8 BOM
        rescue => e
        end

        File.write @file, txt_file

        @params_fec = FecImport.new(@file).parse_metadata(params[:separator])

        if @params_fec[:error_message].present?
          flash[:error] = @params_fec[:error_message]

          redirect_to organization_customer_accounting_plan_path(@organization, @customer)
          return false
        else
          @customer.account_book_types.each { |jl| journal << jl.name }

          @params_fec = @params_fec.merge(dir: @dir, file: @file, journal_ido: journal, separator: params[:separator])
        end
      end
    else
      flash[:error] = 'Aucun fichier choisi.'
    end

    if params[:new_create_book_type].present?
      if @params_fec.present?
        @params_fec = @params_fec.merge(new_create_book_type: params[:new_create_book_type])
        render :partial => "/accounting_plans/main/dialog_box", locals: { organization: @organization, customer: @customer, params_fec: @params_fec }
      end
    else
      render :show
    end
  end

  def import_fec_processing
    file_path  = params[:file_path]

    FecImport.new(file_path).execute(@customer, params)

    FileUtils.remove_entry(params[:dir_tmp], true) if params[:dir_tmp]

    if params[:new_create_book_type].present?
      render partial: '/account/customers/table', locals: { providers: @customer.accounting_plan.providers, customers: @customer.accounting_plan.customers }
    else      
      redirect_to organization_customer_accounting_plan_path(@organization, @customer)
    end
  end

  # DELETE /organizations/:organization_id/customers/:customer_id/accounting_plan/destroy_providers
  def destroy_providers
    @accounting_plan.providers.clear

    @accounting_plan.general_account_providers = ""
    @accounting_plan.save

    flash[:success] = 'Fournisseurs supprimés avec succès.'
    
    redirect_to organization_customer_accounting_plan_path(@organization, @customer)
  end

  # DELETE /organizations/:organization_id/customers/:customer_id/accounting_plan/destroy_customers
  def destroy_customers
    @accounting_plan.customers.clear

    @accounting_plan.general_account_customers = ""
    @accounting_plan.save

    flash[:success] = 'Clients supprimés avec succès.'
    
    redirect_to organization_customer_accounting_plan_path(@organization, @customer)
  end

  def insert_general_account
    if params[:kind] == 'provider'
      @accounting_plan.general_account_providers = params[:general_account]
    else
      @accounting_plan.general_account_customers = params[:general_account]
    end

    if @accounting_plan.save
      json_flash[:success] = 'Modifié avec succès.'
    else
      json_flash[:error] = errors_to_list @accounting_plan
    end

    render json: { json_flash: json_flash, url: organization_customer_accounting_plan_path(@organization, @customer, { tab: params[:kind]}) }, status: 200
  end

  private

  def load_customer
    @customer = customers.find params[:customer_id]
  end

  def verify_if_customer_is_active
    if @customer.inactive?
      flash[:error] = t('authorization.unessessary_rights')

      redirect_to organization_path(@organization)
    end
  end

  def load_accounting_plan
    @accounting_plan = @customer.accounting_plan
  end

  def verify_rights
    unless (@user.leader? || @user.manage_customers)
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to organization_path(@organization)
    end
  end

  def items_params
    params[:accounting_plan_item].except(:id, :type).permit(:third_party_account, :third_party_name, :conterpart_account, :code, :vat_autoliquidation_debit_account, :vat_autoliquidation_credit_account, :vat_autoliquidation, :vat_not_recoverable)
  end

  def accounting_plan_params
    attributes = {}

    if params[:accounting_plan]
      if params[:accounting_plan][:providers_attributes].present?
        attributes[:providers_attributes] = params[:accounting_plan][:providers_attributes].permit!
      end

      if params[:accounting_plan][:customers_attributes].present?
        attributes[:customers_attributes] = params[:accounting_plan][:customers_attributes].permit!
      end
    end

    attributes
  end

  def auto_update_accounting_plan_active?
    params[:auto_updating_accounting_plan] == 1
  end

  def update_conterpart_accounts(accounting_plan_item)
    _kind = accounting_plan_item.kind == 'customer' ? 'customer' : 'provider'
    ids   = params[:accounting_plan_item].try(:[], :conterpart_accounts) || []
    ids   += @accounting_plan.conterpart_accounts.is_default.send(_kind.to_s).map(&:id)

    accounting_plan_item.update( conterpart_accounts: ConterpartAccount.where(id: ids) )
  end
end