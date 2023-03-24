# frozen_string_literal: true
class AccountNumberRules::MainController < OrganizationController
  before_action :load_account_number_rule, only: %w[show edit update destroy]

  prepend_view_path('app/templates/front/account_number_rules/views')

  # GET /account/organizations/:organization_id/account_number_rules
  def index
    session[:account_number_rule_contains] = params[:account_number_rule_contains] || session[:account_number_rule_contains]

    session[:account_number_rule_contains_page]            = {}                if session[:account_number_rule_contains_page].nil?
    session[:account_number_rule_contains_page][:page]     = params[:page]     if params[:page]
    session[:account_number_rule_contains_page][:per_page] = params[:per_page] if params[:per_page]

    session[:account_number_rule_contains]     = nil if params[:reinit]
    session[:account_number_rule_contains_nil] = nil  if params[:reinit]

    params[:page]     = session[:account_number_rule_contains_page].try(:[], :page)
    params[:per_page] = session[:account_number_rule_contains_page].try(:[], :per_page)

    @account_number_rules = AccountNumberRule.search_for_collection(@organization.account_number_rules, search_terms(session[:account_number_rule_contains])).order(sort_column => sort_direction)

    @account_number_rules_count = @account_number_rules.count

    @account_number_rules = @account_number_rules.page(params[:page]).per(params[:per_page])

    @list_accounts = @user.customers
    @list_skiped_accounting_plan = @list_accounts.select { |c| c.options.skip_accounting_plan_finder }
    @validated_accounts_list     = @list_accounts.select { |c| c.options.keep_account_validation }
  end

  # GET /account/organizations/:organization_id/account_number_rules/:id
  def show; end

  # GET /account/organizations/:organization_id/account_number_rules/new
  def new
    @account_number_rule = AccountNumberRule.new
    if params[:template].present?
      template = @organization.account_number_rules.find params[:template]
      @account_number_rule.name                = template.name_pattern + " (#{template.similar_name.size + 1})"
      @account_number_rule.affect              = template.affect
      @account_number_rule.rule_type           = template.rule_type
      @account_number_rule.content             = template.content
      @account_number_rule.third_party_account = template.third_party_account
      @account_number_rule.priority            = template.priority
      @account_number_rule.users               = template.users
    end
  end

  # POST /account/organizations/:organization_id/account_number_rules
  def create
    @account_number_rule = AccountNumberRule.new account_number_rule_params

    @account_number_rule.organization = @organization

    if @account_number_rule.save
      json_flash[:success] = 'Créé avec succès.'
    else
      json_flash[:error] = errors_to_list @account_number_rule
    end

    render json: { json_flash: json_flash }, status: 200
  end

  # GET /account/organizations/:organization_id/account_number_rules/:id/edit
  def edit; end

  # PUT /account/organizations/:organization_id/account_number_rules/:id
  def update
    # re-assign customers of other collaborators
    if params[:account_number_rule] && params[:account_number_rule][:user_ids].present?
      params[:account_number_rule][:user_ids] += (@account_number_rule.users - customers).map(&:id).map(&:to_s)
    end

    if @account_number_rule.update(account_number_rule_params)
      json_flash[:success] = 'Modifié avec succès.'
   else
      json_flash[:error] = errors_to_list @account_number_rule
    end

    render json: { json_flash: json_flash }, status: 200
  end

  # DELETE /account/organizations/:organization_id/account_number_rules/:id
  def destroy
    @account_number_rule.destroy

    flash[:success] = 'Supprimé avec succès.'

    redirect_to organization_account_number_rules_path(@organization)
  end

  # POST /account/organizations/:organization_id/account_number_rules/export_or_destroy
  def export_or_destroy
    @account_number_rules = params[:export_type_submit] == 'all' ? AccountNumberRule.where(organization: @organization) : AccountNumberRule.where(id: params[:rules].try(:[], :rule_ids) || [])

    if @account_number_rules.any?
      case params[:export_or_destroy]
      when 'export'
        data = Transaction::AccountNumberRulesToXls.new(@account_number_rules).execute

        send_data data, type: 'application/vnd.ms-excel', filename: 'Affectation.xls'
      when 'destroy'
        @account_number_rules.destroy_all

        flash[:success] = "Règles d'affectations supprimées avec succès."
        redirect_to organization_account_number_rules_path(@organization)
      end
    else
      flash[:alert] = "Veuillez sélectionner les règles d'affectations à exporter ou à supprimer."

      redirect_to organization_account_number_rules_path(@organization)
    end
  end

  # GET /account/organizations/:organization_id/account_number_rules/import_model
  def import_model
    data = [
      ['PRIORITE;NOM;TYPE;CIBLE;CATEGORISATION;CONTENU_RECHERCHE;NUMERO_COMPTE'],
      ['0;AYM GAN;RECHERCHE;CREDIT;BANQUE;PRLV SEPA GAN;0GAN'],
      ['0;ORG;RECHERCHE;DEBIT;BANQUE;PRLV ORG;0RG'],
      ['0;EXO;CORRECTION;TOUS;IMPOT;EXO;']
    ]

    send_data(data.join("\n"), type: 'plain/text', filename: "modèle d'import.csv")
  end

  # GET /account/organizations/:organization_id/account_number_rules/import_form
  def import_form; end

  # GET /account/organizations/:organization_id/account_number_rules/import
  def import
    file = params[:file]

    if file
      if AccountNumberRule.import(file, params[:account_number_rule], @organization)
        flash[:success] = 'Importé avec succès.'
      else
        flash[:error] = 'Fichier non valide.'
      end
    else
      flash[:error] = 'Aucun fichier choisi.'
    end

    redirect_to organization_account_number_rules_path(@organization)
  end

  def update_skip_accounting_plan_accounts
    update_option('skip_accounting_plan_finder', 'account_list') if params[:account_list]

    update_option('keep_account_validation', 'account_validation') if params[:account_validation]

    render json: { json_flash: { success: 'Modification effectué' } }, status: 200
  end

  private

  def sort_column
    params[:sort] || 'name'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'asc'
  end
  helper_method :sort_direction

  def account_number_rule_params
    attributes = %i[
      name
      rule_target
      rule_type
      content
      priority
      third_party_account
      categorization
    ]
    
    params[:account_number_rule][:third_party_account] = nil if params[:account_number_rule][:rule_type] == 'truncate'

    attributes << :affect
    attributes << { user_ids: [] } if params[:account_number_rule][:affect] == 'user'

    params.require(:account_number_rule).permit(*attributes)
  end

  def load_account_number_rule
    @account_number_rule = @organization.account_number_rules.find params[:id]
  end

  def update_option(field, param_content)
    @user.customers.each { |customer| customer.options.update(field.to_sym => (params[param_content.to_sym].include? customer.info) ? true : false) }
  end
end