# frozen_string_literal: true

class CustomerController < OrganizationController
  before_action :is_customer_layout

  protected

  def is_customer_layout
    @is_customer_layout = true
  end

  def can_manage?
    @user.leader? || @user.manage_customers
  end

  def verify_rights
    authorized = true
    authorized = false unless can_manage?
    if action_name.in?(%w[account_close_confirm close_account]) && params[:close_now] == '1' && !@user.is_admin
      authorized = false
    end
    if action_name.in?(%w[info new create destroy]) && !@organization.is_active
      authorized = false
    end
    if action_name.in?(%w[info new create destroy]) && !(@user.leader? || @user.groups.any?)
      authorized = false
    end
    if action_name.in?(%w[edit_setting_options update_setting_options]) && !@customer.authorized_upload?
      authorized = false
    end
    if action_name.in?(%w[edit_exact_online update_exact_online]) && !@organization.try(:exact_online).try(:used?)
      authorized = false
    end

    unless authorized
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to organization_path(@organization)
    end
  end

  def verify_if_customer_is_active
    if @customer.inactive?
      flash[:error] = t('authorization.unessessary_rights')

      redirect_to organization_path(@organization)
    end
  end

  def verify_if_account_can_be_closed
    if !@customer.subscription.commitment_end?(false) && !params[:close_now]
      flash[:error] = 'Ce dossier est souscrit à un forfait avec un engagement de 12 mois'

      redirect_to organization_customer_path(@organization, @customer)
    end
  end

  def build_softwares
    Interfaces::Software::Configuration::SOFTWARES.each do |software|
      @customer.send("build_#{software}".to_sym) if @customer.send(software.to_sym).nil?
    end
  end

  def load_customer
    @customer = customers.find(params[:id])
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction
end