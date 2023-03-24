# frozen_string_literal: true

class Organizations::MainController < OrganizationController
  before_action :verify_suspension, only: %w[show edit update]
  before_action :load_organization, except: %w[index edit_options update_options new create]
  before_action :apply_membership
  before_action :verify_rights

  prepend_view_path('app/templates/front/organizations/views')

  # GET /account/organizations/:id/update_options
  def edit_options; end

  # PUT /account/organizations/:id/update_options
  def update_options
    Settings.first.update(is_journals_modification_authorized: params[:settings][:is_journals_modification_authorized] == '1')
    flash[:success] = 'Modifié avec succès.'
    redirect_to account_organizations_path
  end

  # GET /account/organizations/:id/
  def show
    date                   = Time.now.beginning_of_month
    @stat_customers_labels = []
    @stat_customers_values = []
    
    6.times do |i|
      date = date - 1.month

      @stat_customers_labels << date.strftime('%m/%Y')
      @stat_customers_values << @organization.customers.active_at(date).size
    end
    # @members = @organization.customers.page(params[:page]).per(params[:per])
    # @periods = Period.where(user_id: @organization.customers.pluck(:id)).where('start_date < ? AND end_date > ?', Date.today, Date.today).includes(:billings)
  end

  # GET /account/organizations/:id/edit
  def edit; end

  # PUT /account/organizations/:id
  def update
    if params[:part].present? && organization_params["#{params[:part]}_attributes"].present?
      case params[:part]
      when 'my_unisoft'
        is_used         = organization_params['my_unisoft_attributes']['is_used'] == "1"
        auto_deliver    = organization_params['my_unisoft_attributes']['auto_deliver']

        result = MyUnisoftLib::Setup.new({organization: @organization, columns: {is_used: is_used, auto_deliver: auto_deliver}}).execute
      when 'sage_gec'
        is_used         = organization_params['sage_gec_attributes']['is_used'] == "1"
        auto_deliver    = organization_params['sage_gec_attributes']['auto_deliver']

        result = SageGecLib::Setup.new({organization: @organization, columns: {is_used: is_used, auto_deliver: auto_deliver}}).execute
      when 'acd'
        is_used         = organization_params['acd_attributes']['is_used'] == "1"
        auto_deliver    = organization_params['acd_attributes']['auto_deliver']

        result = AcdLib::Setup.new({organization: @organization, columns: {is_used: is_used, auto_deliver: auto_deliver}}).execute
      else
        is_used         = organization_params["#{params[:part]}_attributes"]['is_used'] == "1"
        auto_deliver    = organization_params["#{params[:part]}_attributes"]['auto_deliver']
        result = Software::UpdateOrCreate.assign_or_new({owner: @organization, columns: {is_used: is_used, auto_deliver: auto_deliver}, software: params[:part]})
      end

      if result
        json_flash[:success] = 'Modifié avec succès.'
      else
        json_flash[:error] = 'Erreur de mise à jour.'
      end
    elsif @organization.update(organization_params)
      json_flash[:success] = 'Modifié avec succès.'
    else
      json_flash[:error] = 'Erreur de mise à jour.'
    end

    render json: { json_flash: json_flash }, status: 200
  end

  def statistic
    date      = Time.now.beginning_of_month
    customers = @organization.customers.active_at(date)

    @organization_statistic = { micro_package: 0, nano_package: 0, basic_package: 0, mail_package: 0, scan_box_package: 0, retriever_package: 0, mini_package: 0, idox_package: 0, digitize_package: 0, premium_package: 0 }

    customers.each do |customer|
      package = customer.my_package
      next if not package

      case package.name
        when 'ido_classic'
          @organization_statistic[:basic_package] += 1
        when 'ido_nano'
          @organization_statistic[:nano_package] += 1
        when 'ido_x'
          @organization_statistic[:idox_package] += 1
        when 'ido_micro'
          @organization_statistic[:micro_package] += 1
        when 'ido_micro_plus'
          @organization_statistic[:micro_package] += 1
        when 'ido_retriever'
          @organization_statistic[:retriever_package] += 1
        when 'ido_digitize'
          @organization_statistic[:digitize_package] += 1
        when 'ido_premium'
          @organization_statistic[:premium_package] += 1
        end

        @organization_statistic[:mail_package] += 1       if package.mail_active
        @organization_statistic[:retriever_package] += 1  if package.bank_active && package.name != 'ido_retriever'
        @organization_statistic[:digitize_package] += 1   if package.digitize_active && package.name != 'ido_digitize'
    end


    render partial: 'statistic'
  end

  # PUT /account/organizations/:id/activate
  def activate
    @organization.update_attribute(:is_active, true)
    flash[:success] = 'Activé avec succès.'
    redirect_to organization_path(@organization)
  end

  # PUT /account/organizations/:id/deactivate
  def deactivate
    Organization::Deactivate.new(@organization.id.to_s).execute
    @organization.update_attribute(:is_active, false)
    flash[:success] = 'Désactivé avec succès.'
    redirect_to organization_path(@organization)
  end

  # GET /account/organizations/:id/close_confirm
  def close_confirm; end

  private

  def verify_rights
    unless current_user.is_admin
      authorized = false
      if current_user.is_admin && action_name.in?(%w[index edit_options update_options edit_software_users update_software_users new create suspend unsuspend])
        authorized = true
      elsif action_name.in?(%w[show statistic]) && @user.is_prescriber
        authorized = true
      elsif action_name.in?(%w[edit update edit_software_users update_software_users]) && @user.leader?
        authorized = true
      end

      unless authorized
        flash[:error] = t('authorization.unessessary_rights')
        redirect_to root_path
      end
    end
  end

  def organization_params
    if current_user.is_admin
      params.require(:organization).permit(
        :name,
        :code,
        :authd_prev_period,
        :auth_prev_period_until_day,
        :invoice_created_customer,
        :is_detail_authorized,
        :is_test,
        :is_pre_assignment_date_computed,
        :is_operation_processing_forced,
        :is_operation_value_date_needed,
        :is_duplicate_blocker_activated,
        :preseizure_date_option,
        :subject_to_vat,
        :invoice_mails,
        :jefacture_api_key,
        :specific_mission,
        :default_banking_provider,
        :cedricom_name,
        :cedricom_user,
        :cedricom_password,
        :jedeclare_account_identifier,
        :jedeclare_user,
        :jedeclare_password,
        { :quadratus_attributes => %i[id is_used auto_deliver] },
        { :coala_attributes => %i[id is_used auto_deliver] },
        { :cegid_attributes => %i[id is_used auto_deliver] },
        { :fec_agiris_attributes => %i[id is_used auto_deliver] },
        { :csv_descriptor_attributes => %i[id is_used auto_deliver] },
        { :exact_online_attributes => %i[id is_used auto_deliver] },
        { :my_unisoft_attributes => %i[id is_used auto_deliver] },
        { :sage_gec_attributes => %i[id is_used auto_deliver] },
        { :acd_attributes => %i[id is_used auto_deliver] }
      )
    else
      params.require(:organization).permit(
        :name,
        :authd_prev_period,
        :auth_prev_period_until_day,
        :is_pre_assignment_date_computed,
        :is_operation_processing_forced,
        :is_operation_value_date_needed,
        :is_duplicate_blocker_activated,
        :preseizure_date_option,
        :invoice_mails,
        :jefacture_api_key,
        :cedricom_name,
        :cedricom_user,
        :cedricom_password,
        :jedeclare_account_identifier,
        :jedeclare_user,
        :jedeclare_password,
        { :quadratus_attributes => %i[id is_used auto_deliver] },
        { :coala_attributes => %i[id is_used auto_deliver] },
        { :cegid_attributes => %i[id is_used auto_deliver] },
        { :fec_agiris_attributes => %i[id is_used auto_deliver] },
        { :csv_descriptor_attributes => %i[id is_used auto_deliver] },
        { :exact_online_attributes => %i[id is_used auto_deliver] },
        { :my_unisoft_attributes => %i[id is_used auto_deliver] },
        { :sage_gec_attributes => %i[id is_used auto_deliver] },
        { :acd_attributes => %i[id is_used auto_deliver] }
      )
    end
  end

  def to_redirect
    if params[:part].present?
      redirect_to organization_path(@organization, tab: params[:part])
    else
      redirect_to organization_path(@organization)
    end
  end

  def sort_column
    params[:sort] || 'name'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'asc'
  end
  helper_method :sort_direction
end