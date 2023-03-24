# frozen_string_literal: true

class SoftwareSetting::UserController < CustomerController

  before_action :load_customer
  before_action :verify_rights

  prepend_view_path('app/templates/front/software_setting/views')

  # GET /organizations/:organization_id/customers
  def index
    build_softwares
  end

  private

  def load_customer
    @customer = customers.find(params[:id] || params[:customer_id])
  end

  def can_manage?
    @user.leader? || @user.manage_customers
  end

  def verify_rights
    authorized = true
    authorized = false unless can_manage?

    unless authorized
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to organization_path(@organization)
    end
  end
end