# frozen_string_literal: true
class VatAccounts::MainController < OrganizationController
  before_action :load_customer
  before_action :verify_if_customer_is_active
  before_action :load_accounting_plan
  before_action :verify_rights

  prepend_view_path('app/templates/front/vat_accounts/views')

  # GET /organizations/:organization_id/customers/:customer_id/accounting_plan/vat_accounts
  def index
    @vat_accounts = @accounting_plan.vat_accounts
  end

  def edit
    @vat_accounts = @accounting_plan.vat_accounts.find(params[:id])
    
    render partial: 'edit'
  end

  def update
    vat_account = @accounting_plan.vat_accounts.find(params[:id])
    vat_account.assign_attributes(params[:accounting_plan_vat_account].permit(:code, :nature, :account_number))
    
    if vat_account.save
      json_flash[:success] = 'Modifié avec succès.'
    else
      json_flash[:error] = errors_to_list vat_account
    end

    render json: { json_flash: json_flash, url: organization_customer_accounting_plan_path(@organization, @customer, { tab: 'vat_accounts'}) }, status: 200   
  end

  def new
    @vat_accounts = @accounting_plan.vat_accounts.new
    
    render partial: 'edit'
  end

  def create
    vat_account = @accounting_plan.vat_accounts.new

    vat_account.assign_attributes(params[:accounting_plan_vat_account].permit(:code, :nature, :account_number))
    
    if vat_account.save
      json_flash[:success] = 'Ajouté avec succès.'
    else
      json_flash[:error] = errors_to_list vat_account
    end

    render json: { json_flash: json_flash, url: organization_customer_accounting_plan_path(@organization, @customer, { tab: 'vat_accounts'}) }, status: 200
  end

  def destroy
    vat_account = @accounting_plan.vat_accounts.find(params[:id])

    vat_account.destroy    

    flash[:success] = 'Compte TVA supprimés avec succès.'

    redirect_to organization_customer_accounting_plan_path(@organization, @customer, { tab: 'vat_accounts'})    
  end

  # /organizations/:organization_id/customers/:customer_id/accounting_plan/update_multiple
  # def update_multiple
  #   modified = params[:accounting_plan].present? ? @accounting_plan.update(accounting_plan_params) : true

  #   respond_to do |format|
  #     format.html {
  #       if modified
  #         flash[:success] = 'Modifié avec succès.'
  #         redirect_to organization_customer_accounting_plan_vat_accounts_path(@organization, @customer)
  #       else
  #         render :edit_multiple
  #       end
  #     }
  #     format.json {
  #       if params[:destroy].present? && params[:id].present?
  #         @accounting_plan.vat_accounts.find(params[:id]).destroy
  #         vat_account = nil
  #       elsif params[:accounting_plan][:vat_accounts_attributes][:id].present?
  #         vat_account = @accounting_plan.vat_accounts.find(params[:accounting_plan][:vat_accounts_attributes][:id])
  #       else
  #         vat_account = AccountingPlanVatAccount.unscoped.where(accounting_plan_id: @accounting_plan.id).order(id: :desc).first
  #       end

  #       render json: { account: vat_account  }, status: 200
  #     }
  #   end
  # end

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

  def accounting_plan_params
    { vat_accounts_attributes: params[:accounting_plan][:vat_accounts_attributes].permit! }
  end
end