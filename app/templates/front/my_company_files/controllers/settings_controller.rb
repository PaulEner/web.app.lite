# frozen_string_literal: true

class MyCompanyFiles::SettingsController < OrganizationController
  before_action :verify_rights
  before_action :load_mcf_settings
  before_action :set_state,   only: :authorize
  after_action  :reset_state, only: :callback

  prepend_view_path('app/templates/front/my_company_files/views')

  def update
    if @mcf_settings.update(mcf_settings_params)
      json_flash[:success] = 'Modifié avec succès.'
    else
      json_flash[:error] = 'Impossible de modifier vos paramètres.'
    end

    render json: { json_flash: json_flash }, status: 200
  end

  def destroy
    @mcf_settings.reset

    flash[:success] = 'Vos paramètres pour My Company Files ont été supprimé.'
    
    render json: { json_flash: json_flash }, status: 200
  end

  def authorize
    url = Rails.application.credentials[Rails.env.to_sym][:my_company_files_api][:authorize_url] + '?'
    url += {
      client_id: @user.id,
      client_name: Rails.application.credentials[Rails.env.to_sym][:my_company_files_api][:client_name],
      redirect_uri: callback_organization_mcf_settings_url(@organization),
      state: state
    }.to_param

    redirect_to url
  end

  def callback
    if params[:access_token].present? && params[:refresh_token].present? && params[:expiration_date].present?
      @mcf_settings.update(
        access_token: params[:access_token],
        refresh_token: params[:refresh_token],
        access_token_expires_at: params[:expiration_date].to_i / 1000
      )
      flash[:success] = 'Votre compte My Company Files a bien été lié à iDocus.'
    elsif params[:error]&.match(/access_denied/)
      flash[:error] = 'Vous avez refusé de lier votre compte My Company Files à iDocus.'
    else
      flash[:error] = 'La requête est invalide ou la session a expiré.'
    end

    redirect_to organization_efs_path(@organization, tab: 'mcf')
  end

  private

  def verify_rights
    unless @user.leader?
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to organization_path(@organization)
    end
  end

  def load_mcf_settings
    @mcf_settings = @organization.mcf_settings || McfSettings.create(organization: @organization)
  end

  def mcf_settings_params
    params.require(:mcf_settings).permit(:is_delivery_activated, :delivery_path_pattern)
  end

  def state
    Rails.cache.read [:mcf_oauth_state, @organization.id]
  end

  def set_state
    Rails.cache.write [:mcf_oauth_state, @organization.id], SecureRandom.hex(30), expires_in: 15.minutes
  end

  def reset_state
    Rails.cache.write [:mcf_oauth_state, @organization.id], nil, expires_in: 1.minutes
  end
end
