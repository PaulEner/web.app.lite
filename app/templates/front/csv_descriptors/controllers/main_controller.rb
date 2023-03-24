# frozen_string_literal: true
class CsvDescriptors::MainController < OrganizationController
  before_action :verify_rights
  before_action :load_csv_descriptor

  prepend_view_path('app/templates/front/csv_descriptors/views')

  # GET /organizations/:organization_id/csv_descriptor/edit
  def format_setting
    render partial: 'format_setting'
  end

  # PUT /organizations/:organization_id/customers/:customer_id/csv_descriptor
  def update
    if @csv_descriptor.update(csv_descriptor_params)
      @csv_descriptor.update(use_own_csv_descriptor_format: true) if(params[:user_id]) #activate custom format if edited, for user only

      json_flash[:success] = 'Modifié avec succès.'
    else
      json_flash[:error] = 'Modification impossible.'
    end

    render json: { json_flash: json_flash }, status: 200
  end

  # PUT  /organizations/:organization_id/customers/:customer_id/csv_descriptor/deactivate
  def deactivate
    @csv_descriptor.update_attribute(:use_own_csv_descriptor_format, false)

    flash[:success] = 'Modifié avec succès.'

    redirect_to organization_customer_path(@organization, params[:user_id], tab: 'csv_descriptor')
  end

  private

  def verify_rights
    unless @user.is_admin || (@user.is_prescriber && @user.organization == @organization) || @organization.try(:csv_descriptor).try(:used?)
      json_flash[:error] = t('authorization.unessessary_rights')
      render json:{ json_flash: json_flash }, status: 200
    end
  end

  def load_csv_descriptor
    if(params[:user_id])
      @csv_descriptor = User.find(params[:user_id]).csv_descriptor
    else
      @csv_descriptor = @organization.csv_descriptor
    end
  end

  def csv_descriptor_params
    params.require(:software_csv_descriptor).permit(:directive, :comma_as_number_separator)
  end
end