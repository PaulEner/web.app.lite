# frozen_string_literal: true
class Ibiza::BoxFoldersController < CustomerController
  before_action :load_customer
  before_action :verify_rights
  before_action :verify_if_customer_is_active

  prepend_view_path('app/templates/front/ibiza/views')

  def update
    @folder = @customer.ibizabox_folders.find params[:id]
    if @folder.active? ? @folder.disable : @folder.enable
      json_flash[:success] = "#{@folder.active? ? 'Activé' : 'Désactivé'} avec succès"
    else
      json_flash[:error] = "#{@folder.active? ? 'Désactivation' : 'Activation'} échouée"
    end

    render json: { json_flash: json_flash }, status: 200
  end

  def refresh
    FileImport::Ibizabox.update_folders(@customer)
    json_flash[:success] = 'Mise à jour avec succès'

    render json: { json_flash: json_flash }, status: 200
  end

  private

  def load_customer
    @customer = customers.find(params[:customer_id])
  end

  def verify_rights
    is_ok = false
    if @organization.is_active
      is_ok = true if @user.leader?
      is_ok = true if !is_ok && !@customer && @user.manage_journals
      is_ok = true if !is_ok && @customer && @user.manage_customer_journals
    end
    unless is_ok
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to organization_path(@organization)
    end
  end

  def verify_if_customer_is_active
    if @customer&.inactive?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to organization_path(@organization)
    end
  end
end