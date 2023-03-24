# frozen_string_literal: true
class AccountingPlans::ConterpartAccountController < CustomerController
  before_action :load_customer

  prepend_view_path('app/templates/front/accounting_plans/views')

  def show
    if params[:kind] == 'customer'
      accounting_plan_items   = @customer.accounting_plan.active_customers.order(:third_party_name)
    else
      accounting_plan_items   = @customer.accounting_plan.active_providers.order(:third_party_name)
    end

    @accounting_plan_items = accounting_plan_items.map{ |account| ["#{account.third_party_name} - #{account.third_party_account}", account.id] }

    render partial: 'show'
  end

  def accounts_list
    if params[:type] == 'customer'
      _accounts = @customer.conterpart_accounts.customer.order(:name)
    else
      _accounts = @customer.conterpart_accounts.provider.order(:name)
    end

    accounts = _accounts.map{|account| { id: account.id, name: account.name, number: account.number } }

    render json: { accounts: accounts }, status: 200
  end

  def link
    conterpart_accounts_ids = params[:conterpart_account].try(:[], :conterpart_accounts) || []
    third_party_ids         = params[:conterpart_account].try(:[], :accounting_plan_items) || []

    error_mess = ''
    error_mess = 'Veuillez sélectionner une/des catégorie(s)' if conterpart_accounts_ids.empty?
    error_mess = 'Veuillez sélectionner un/des compte(s) de tiers' if third_party_ids.empty?

    if error_mess.blank?
      conterpart_accounts_ids.each do |account_id|
        account = @customer.conterpart_accounts.where(id: account_id).first
        next if not account

        third_party_assigned = account.accounting_plan_items
        third_party_list     = AccountingPlanItem.where(id: third_party_ids)

        to_assign = (third_party_assigned + third_party_list).uniq

        account.update(accounting_plan_items: to_assign)
      end

      json_flash[:success] = 'Mise à jour effectuée.'
    else
      json_flash[:error] = error_mess
    end

    render json: { json_flash: json_flash }, status: 200
  end

  def edit
    if params[:action_kind] == 'third_part'
      if params[:kind] == 'customer'
        _accounts    = @customer.accounting_plan.active_customers
        _conterparts = @customer.conterpart_accounts.customer
      else
        _accounts    = @customer.accounting_plan.active_providers
        _conterparts = @customer.conterpart_accounts.provider
      end

      @account = _accounts.where(id: params[:id].to_i).first
      @conterpart_accounts = _conterparts.map{|account| ["#{account.name} - #{account.number}", account.id] }

      render partial: 'edit_third_part'
    else
      @conterpart_account      = @customer.conterpart_accounts.where(id: params[:id].to_i).first || ConterpartAccount.new
      @conterpart_account.kind = params[:kind].presence || 'provider'

      if params[:kind] == 'customer'
        accounting_plan_items   = @customer.accounting_plan.active_customers.order(:third_party_name)
      else
        accounting_plan_items   = @customer.accounting_plan.active_providers.order(:third_party_name)
      end

      @accounting_plan_items = accounting_plan_items.map{ |account| ["#{account.third_party_name} - #{account.third_party_account}", account.id] }
      
      render partial: 'edit_conterpart'
    end
  end

  def update
    if params[:edit] == 'third_part'
      @account   = @customer.accounting_plan.active_customers.where(id: params[:accounting_plan_item][:id].to_i).first
      @account ||= @customer.accounting_plan.active_providers.where(id: params[:accounting_plan_item][:id].to_i).first

      @conterpart_accounts = @customer.conterpart_accounts.where(id: params[:accounting_plan_items].try(:[], :conterpart_accounts))

      if @account.update(conterpart_accounts: @conterpart_accounts)
        json_flash[:success] = 'Mise à jour effectuée'
      else
        json_flash[:error] = errors_to_list(@account)
      end
    else
      @conterpart_account = @customer.conterpart_accounts.where(id: params[:conterpart_account][:id].to_i).first || ConterpartAccount.new

      @conterpart_account.user            = @customer
      @conterpart_account.accounting_plan = @customer.accounting_plan

      @conterpart_account.assign_attributes(_params)

      if @conterpart_account.save
        if @conterpart_account.is_default
          _kind = @conterpart_account.kind == 'customer' ? 'active_customers' : 'active_providers'
          @conterpart_account.update( accounting_plan_items: @customer.accounting_plan.send(_kind.to_sym) )
        else
          @conterpart_account.update( accounting_plan_items: AccountingPlanItem.where(id: params[:conterpart_account].try(:[], :accounting_plan_items)) )
        end

        json_flash[:success] = 'Mise à jour effectuée.'
      else
        json_flash[:error]  = errors_to_list(@conterpart_account)
      end
    end

    render json: { json_flash: json_flash }, status: 200
  end

  def delete
    if params[:ids].present?
      ids = params[:ids].split(',')
      @customer.conterpart_accounts.where(id: ids).destroy_all
    end

    render json: { json_flash: { success: 'Supprimer avec succès.' } }, status: 200
  end

  def select_from_customer
    selected_customer = User.find params[:selected_id]

    if params[:kind] == 'customer'
      _accounts = selected_customer.conterpart_accounts.customer.order(:name)
    else
      _accounts = selected_customer.conterpart_accounts.provider.order(:name)
    end

    accounts = _accounts.map{|account| { id: account.id, name: account.name, number: account.number } }

    render json: { accounts: accounts }, status: 200
  end

  def validate_from_customer
    selected_customer   = User.find params[:from_customer][:customer]
    conterpart_accounts = selected_customer.conterpart_accounts.where(id: params[:from_customer][:conterpart_accounts])

    conterpart_accounts.each do |account|
      new_account = @customer.conterpart_accounts.where(name: account.name, number: account.number).first
      next if new_account

      new_account = account.dup
      new_account.accounting_plan = @customer.accounting_plan

      @customer.conterpart_accounts << new_account
    end

    if @customer.save
      json_flash[:success] = 'Mise à jour effectuée.'
    else
      json_flash[:error] = 'Action impossible, Veuillez reéssayer ultérieurement.'
    end

    render json: { json_flash: json_flash }, status: 200
  end

  private

  def _params
    params.require(:conterpart_account).permit(:name, :number, :kind, :is_default)
  end

  def load_customer
    @customer = customers.find params[:customer_id]
  end
end