# frozen_string_literal: true
class Admin::PackageSetting::MainController < BackController
  prepend_view_path('app/templates/back/package_setting/views')

  # GET /admin/reset
  def index; end

  def update_customers
    @lists = BillingMod::UpdatePremiumCustomers.new(params[:organization_code].strip).execute

    render partial: 'list_customers'
  end

  def rollback_customers
    @lists = BillingMod::UpdatePremiumCustomers.new(params[:organization_code].strip).execute("rollback")

    render partial: 'list_customers'
  end
end