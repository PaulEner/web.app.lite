# frozen_string_literal: true
class ExternalFileStorages::EfsUserController < CustomerController
  before_action :load_customer
  before_action :verify_rights

  prepend_view_path('app/templates/front/external_file_storages/views')

  def index; end

  private

  def load_customer
    @customer = customers.find(params[:customer_id])
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