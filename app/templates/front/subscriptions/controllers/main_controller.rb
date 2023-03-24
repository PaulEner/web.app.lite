# frozen_string_literal: true
class Subscriptions::MainController < CustomerController
  before_action :verify_rights
  before_action :load_customer
  before_action :verify_if_customer_is_active
  before_action :load_subscription

  prepend_view_path('app/templates/front/subscriptions/views')

  # /organizations/:organization_id/organization_subscription/edit
  def edit; end

  # PUT /organizations/:organization_id/organization_subscription
  def update
    package_name = params[:package].try(:[], :name)
    options      = params[:package].try(:[], package_name.to_sym)

    create_package = BillingMod::CreatePackage.new(@customer, package_name, options, params[:package].try(:[], :apply_now).present?, current_user).execute

    @customer.update(jefacture_account_id: params[:user][:jefacture_account_id]) if create_package && params.try(:[], :user).try(:[], :jefacture_account_id).present?  

    BillingMod::PrepareUserBilling.new(@customer.reload).execute

    flash[:success] = 'Modifié avec succès.'

    # modif_params = params[:subscription][:subscription_option]
    # params[:subscription][modif_params] = true

    # if Subscription::Form.new(@subscription, @user, request).submit(params[:subscription])
    #   @customer.update(current_configuration_step: nil) unless @customer.configured?

    #   if params.try(:[], :user).try(:[], :jefacture_account_id).present?
    #     @customer.update(jefacture_account_id: params[:user][:jefacture_account_id])
    #   end

    #   flash[:success] = 'Modifié avec succès.'
    # else
    #   flash[:error] = 'Vous devez sélectionner un forfait.'
    # end

    # redirect_to edit_organization_customer_subscription_path(@organization, @customer)
    render json: { json_flash: flash }, status: 200
  end

  private

  def load_customer
    @customer = customers.find params[:customer_id]
  end

  def load_subscription
    @subscription = @customer.subscription
  end

  def verify_rights
    unless @user.leader? || @user.manage_customers
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to organization_path(@organization)
    end
  end
end